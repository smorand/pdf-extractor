# PDF Extractor

A Go-based PDF content extraction tool that extracts text and images from PDF files, with optional AI-powered image analysis using Google Vertex AI.

## Features

- **Text Extraction**: Extract all text content from PDF documents
- **Image Extraction**: Save embedded images as PNG files
- **AI Image Analysis**: Analyze images using Google Vertex AI (Gemini) to generate:
  - Detailed descriptions
  - Image type classification (diagram, chart, photograph, etc.)
  - Suggested captions
- **Markdown Output**: Generate structured markdown files with extracted content
- **JSON Output**: Machine-readable JSON output to stdout
- **Cleanup Mode**: Optionally remove image files after processing

## Installation

### Prerequisites

- Go 1.24 or higher
- GCP credentials (for AI image analysis)

### Build from Source

```bash
make build
```

### Install

```bash
# Install to /usr/local/bin
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

-project string
    GCP project ID for Vertex AI (default: btdp-dta-gbl-0002-gen-ai-01)

-region string
    GCP region for Vertex AI (default: europe-west1)

-model string
    Vertex AI model to use (default: gemini-1.5-flash)

-cleanup
    Clean up image files after processing

-no-ai
    Skip AI image analysis
```

### Examples

```bash
# Extract PDF with default settings
pdf-extractor document.pdf

# Extract without AI analysis
pdf-extractor -no-ai document.pdf

# Extract and cleanup images after processing
pdf-extractor -cleanup document.pdf

# Custom output directory
pdf-extractor -output ./my-extraction document.pdf

# Use different Vertex AI model
pdf-extractor -model gemini-1.5-pro document.pdf
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
  "text": "...",
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

For AI image analysis, ensure you have GCP credentials configured:

```bash
gcloud auth application-default login
```

Or set the service account key:

```bash
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
make test
```

### Format Code

```bash
make fmt
```

### Run Go Vet

```bash
make vet
```

### Run All Checks (fmt + vet + test)

```bash
make check
```

### Clean Build Artifacts

```bash
make clean
```

### Clean All (including go.mod and go.sum)

```bash
make clean-all
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

Sebastien MORAND - sebastien.morand@loreal.com
