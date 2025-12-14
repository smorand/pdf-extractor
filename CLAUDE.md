# PDF Extractor - AI Documentation

## Project Overview

**Name**: pdf-extractor
**Type**: CLI Tool
**Language**: Go 1.24
**Purpose**: Extract text and images from PDF files with optional AI-powered image analysis using Google Vertex AI

## Architecture

### Entry Point
- `src/main.go` - Main entry point with CLI flag parsing and orchestration

### Core Components

1. **PDF Extraction** (`extractPDFContent`)
   - Opens PDF using go-fitz library
   - Iterates through pages extracting text and images
   - Saves images as PNG files
   - Coordinates AI analysis when enabled

2. **AI Image Analysis** (`analyzeImageWithAI`)
   - Uses Google Vertex AI (Gemini) to analyze images
   - Generates descriptions, type classification, and captions
   - Returns structured ImageAnalysis data

3. **Markdown Generation** (`createMarkdownOutput`)
   - Creates structured markdown with text content and image references
   - Includes AI-generated metadata for images

### Data Structures

```go
type ExtractionResult struct {
    Markdown     string          // Complete markdown content
    Text         string          // Raw extracted text
    Images       []ImageAnalysis // Image metadata
    OutputDir    string          // Output directory path
    MarkdownFile string          // Markdown file path
    PDFName      string          // Original PDF filename
}

type ImageAnalysis struct {
    ImagePath   string // Path to saved image
    PageNumber  int    // PDF page number (1-indexed)
    ImageNumber int    // Image sequence number
    Description string // AI-generated description
    Type        string // Image type (diagram, chart, etc.)
    Caption     string // AI-generated caption
}
```

## Configuration

### Default Values
- **GCP Project**: btdp-dta-gbl-0002-gen-ai-01
- **Region**: europe-west1
- **Model**: gemini-1.5-flash

### CLI Flags
- `-output`: Output directory (default: `{pdf_name}_extraction`)
- `-project`: GCP project ID for Vertex AI
- `-region`: GCP region for Vertex AI
- `-model`: Vertex AI model to use
- `-cleanup`: Remove image files after processing
- `-no-ai`: Skip AI image analysis

## Dependencies

### Direct Dependencies
- `github.com/gen2brain/go-fitz@v1.23.7` - PDF rendering and extraction
- `google.golang.org/genai@v1.38.0` - Google Generative AI SDK

### Key Indirect Dependencies
- `cloud.google.com/go/auth` - GCP authentication
- `google.golang.org/grpc` - gRPC communication with Vertex AI

## Build System

### Makefile Targets
- `make build` - Build binary
- `make install` - Install to /usr/local/bin (or TARGET env var)
- `make uninstall` - Remove installed binary
- `make test` - Run tests
- `make fmt` - Format code
- `make clean` - Remove build artifacts

## Authentication

Requires GCP credentials for AI image analysis:
- Application Default Credentials: `gcloud auth application-default login`
- Service Account: Set `GOOGLE_APPLICATION_CREDENTIALS` environment variable

## Output

### File Structure
```
{pdf_name}_extraction/
├── extracted_content.md
└── images/
    └── page_{n}_image_{m}.png
```

### JSON Output (stdout)
Machine-readable JSON with complete extraction results

### Markdown Output (file)
Human-readable markdown with embedded image references

## Error Handling

- PDF file validation before processing
- Graceful degradation for AI analysis failures (continues with basic metadata)
- Proper error propagation with context using `fmt.Errorf` with `%w`
- User-friendly error messages to stderr
- Exit codes: 0 (success), 1 (error)

## Known Issues & Future Improvements

### Code Structure Issues (Non-Compliant)
1. All code in single `main.go` file - should be split into:
   - `cli.go` - CLI handling
   - `extractor.go` - PDF extraction logic
   - `ai.go` - AI image analysis
   - `markdown.go` - Markdown generation
   - `types.go` - Shared types

2. Large functions - `extractPDFContent` should be split into smaller functions:
   - `extractTextFromPages`
   - `extractImagesFromPages`
   - `saveImage`
   - `processPageImage`

3. Magic numbers should be constants:
   - File permissions `0755`, `0644`

4. Color codes (green, red, cyan) should be constants at package level

5. go.mod location - Should be at root level, not in src/

### Potential Enhancements
- Add support for batch processing multiple PDFs
- Implement progress bars for large PDFs
- Add support for OCR on scanned PDFs
- Support additional output formats (JSON file, HTML)
- Add image filtering options (minimum size, type)
- Implement concurrent image analysis for better performance
- Add retry logic for AI API failures
- Support custom AI prompts for image analysis

## Testing Strategy

### Unit Tests Needed
- PDF extraction logic
- Markdown generation
- AI response parsing
- Error handling scenarios

### Integration Tests Needed
- End-to-end extraction with sample PDFs
- AI integration with mock responses
- File system operations

### Test Data
- Sample PDFs with various content types
- Mock AI responses for consistent testing

## Usage Examples

```bash
# Basic extraction
pdf-extractor document.pdf

# Skip AI analysis (faster, no GCP required)
pdf-extractor -no-ai document.pdf

# Extract and cleanup images
pdf-extractor -cleanup document.pdf

# Custom output location
pdf-extractor -output ./results document.pdf

# Use different AI model
pdf-extractor -model gemini-1.5-pro document.pdf
```

## Debugging

### Enable Verbose Output
Current implementation logs to stderr with colored output:
- 🟢 Green: Success messages
- 🔴 Red: Error messages
- 🔵 Cyan: Progress messages

### Common Issues
1. **AI analysis fails**: Check GCP credentials and quota
2. **PDF fails to open**: Verify file format and permissions
3. **Image extraction skipped**: Some PDFs embed images differently; go-fitz may not extract all formats

## AI Integration Details

### Vertex AI Configuration
- Backend: `genai.BackendVertexAI`
- Multimodal input: Text prompt + PNG image
- Response format: JSON (with fallback to raw text)

### AI Prompt Structure
```
Analyze this image and provide:
1. A detailed description of what the image shows
2. The type of image (e.g., diagram, chart, photograph, illustration, screenshot, table)
3. A suggested caption for the image

Respond in JSON format:
{
  "description": "detailed description",
  "type": "image type",
  "caption": "suggested caption"
}
```

### Response Handling
- Attempts JSON parsing with cleanup (removes markdown code blocks)
- Falls back to raw response if JSON parsing fails
- Provides default values on complete failure

## Performance Considerations

- Sequential page processing (potential for parallelization)
- Synchronous AI calls (potential for batch processing)
- In-memory text accumulation (suitable for most PDFs, may need streaming for very large documents)
- Image files written immediately (no buffering)

## Security Considerations

- File path validation needed to prevent path traversal
- No input sanitization on output directory names
- GCP credentials stored in environment/application default credentials
- No rate limiting on AI API calls
