# PDF Extractor

A Go-based PDF content extraction tool that extracts text and images from PDF files, with optional AI-powered image analysis using Google Gemini.

## Features

- **Text Extraction**: Extract all text content from PDF documents with page markers (`--- page N ---`) at the start of each page and a closing `---` marker at the end
- **Image Extraction**: Save embedded images as PNG files
- **AI Image Analysis**: Analyze images using Google Gemini to generate:
  - Detailed descriptions
  - Image type classification (diagram, chart, photograph, etc.)
  - Suggested captions
- **Dual Backend Support**: Use either Vertex AI or Gemini API (Google AI Studio)
- **Markdown Output**: Generate structured markdown files with extracted content
- **JSON Output**: Machine-readable JSON output to stdout
- **Cleanup Mode**: Optionally remove image files after processing

## Project Structure

```
pdf-extractor/
├── cmd/pdf-extractor/main.go    # CLI entry point
├── internal/extractor/          # Core extraction logic
│   ├── types.go                 # Data types
│   ├── constants.go             # Configuration constants
│   ├── extractor.go             # PDF extraction
│   ├── ai.go                    # AI image analysis
│   └── markdown.go              # Markdown generation
├── go.mod / go.sum              # Go module files
└── Makefile                     # Build system
```

## Installation

### Prerequisites

- Go 1.24 or higher
- For AI image analysis: either a Gemini API key or GCP credentials

### Build from Source

```bash
make build
```

### Install

```bash
# Install to ~/.local/bin
make install

# Install to custom location
make install TARGET=/path/to/bin
```

### Uninstall

```bash
make uninstall
```

## Usage

### Basic Usage

```bash
pdf-extractor <pdf-file>
```

### Options

```
-output string
    Output directory for extracted content (default: pdf_name_extraction)

-region string
    GCP region for Vertex AI (default: europe-west1, only used with Vertex AI backend)

-model string
    Gemini model to use (default: gemini-2.5-flash)

-cleanup
    Clean up image files after processing

-no-ai
    Skip AI image analysis
```

### Environment Variables

Configure the AI backend using environment variables:

**For Gemini API (Google AI Studio):**
```bash
export GEMINI_USE_VERTEX_AI=false
export GEMINI_API_KEY="your-api-key"
```

**For Vertex AI:**
```bash
export GEMINI_USE_VERTEX_AI=true  # or leave unset (default)
export GEMINI_GCP_PROJECT="your-gcp-project"
```

### Examples

```bash
# Extract PDF using Vertex AI (default)
export GEMINI_GCP_PROJECT="my-project"
pdf-extractor document.pdf

# Extract PDF using Gemini API
export GEMINI_USE_VERTEX_AI=false
export GEMINI_API_KEY="your-api-key"
pdf-extractor document.pdf

# Extract without AI analysis
pdf-extractor -no-ai document.pdf

# Extract and cleanup images after processing
pdf-extractor -cleanup document.pdf

# Custom output directory
pdf-extractor -output ./my-extraction document.pdf

# Use different Gemini model
pdf-extractor -model gemini-2.5-flash document.pdf
```

## Output

### Directory Structure

```
pdf_name_extraction/
├── extracted_content.md    # Markdown file with all content
└── images/                  # Directory containing extracted images
    ├── page_1_image_1.png
    ├── page_2_image_2.png
    └── ...
```

### JSON Output

The tool outputs JSON to stdout with the following structure:

```json
{
  "markdown": "...",
  "text": "--- page 1 ---\n\nPage 1 text...\n\n--- page 2 ---\n\nPage 2 text...\n\n---\n",
  "images": [
    {
      "image_path": "...",
      "page_number": 1,
      "image_number": 1,
      "description": "...",
      "type": "diagram",
      "caption": "..."
    }
  ],
  "output_dir": "...",
  "markdown_file": "...",
  "pdf_name": "..."
}
```

## Authentication

### Using Gemini API (Google AI Studio)

Set your API key:

```bash
export GEMINI_USE_VERTEX_AI=false
export GEMINI_API_KEY="your-api-key"
```

### Using Vertex AI

Set your GCP project and authenticate:

```bash
export GEMINI_GCP_PROJECT="your-gcp-project"
gcloud auth application-default login
```

Or use a service account:

```bash
export GEMINI_GCP_PROJECT="your-gcp-project"
export GOOGLE_APPLICATION_CREDENTIALS=/path/to/service-account-key.json
```

## Development

### Build

```bash
make build
```

### Rebuild from Scratch

```bash
make rebuild
```

### Run Tests

```bash
make test-unit
```

### Format Code

```bash
make fmt
```

### Run Go Vet

```bash
make vet
```

### Run All Checks (fmt + vet + lint + test)

```bash
make check
```

### Clean Build Artifacts

```bash
make clean
```

### Help

```bash
make help
```

## Dependencies

- [go-fitz](https://github.com/gen2brain/go-fitz) - PDF rendering library
- [google.golang.org/genai](https://pkg.go.dev/google.golang.org/genai) - Google Generative AI SDK

## License

See LICENSE file for details.

## Author

Sebastien MORAND - sebastien.morand@*******
