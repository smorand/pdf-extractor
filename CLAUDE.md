# PDF Extractor - AI Documentation

## Project Overview

**Type**: CLI Tool | **Language**: Go 1.24 | **Module**: `pdf-extractor`
**Purpose**: Extract text and images from PDF files with optional AI-powered image analysis using Google Gemini

## Project Structure

```
pdf-extractor/
├── cmd/pdf-extractor/main.go    # CLI entry point (flag parsing, output)
├── internal/extractor/
│   ├── types.go                 # Config, ExtractionResult, ImageAnalysis
│   ├── constants.go             # Defaults, env vars, permissions, colors
│   ├── extractor.go             # Run() + PDF extraction logic
│   ├── ai.go                    # Gemini AI image analysis
│   └── markdown.go              # Markdown generation
├── go.mod / go.sum              # Root-level module
├── Makefile                     # Standard Go Makefile
└── .agent_docs/                 # Detailed documentation
```

## Key Commands

```bash
make build          # Build for current platform
make install        # Install to ~/.local/bin (or TARGET)
make test-unit      # Run Go unit tests
make fmt            # Format code
make vet            # Run go vet
make check          # fmt + vet + lint + test
make clean          # Remove build artifacts
```

## Essential Conventions

- **Entry point**: `cmd/pdf-extractor/main.go` parses flags, calls `extractor.Run(cfg)`
- **Core logic**: All in `internal/extractor/` package
- **Exported API**: `Config`, `ExtractionResult`, `ImageAnalysis`, `Run()`, `DefaultRegion()`, `DefaultModel()`
- **Error handling**: `fmt.Errorf` with `%w` wrapping
- **Output**: JSON to stdout, progress/errors to stderr with ANSI colors

## Configuration

| Flag | Default | Description |
|------|---------|-------------|
| `-output` | `{pdf}_extraction` | Output directory |
| `-region` | `europe-west1` | GCP region (Vertex AI only) |
| `-model` | `gemini-2.5-flash` | Gemini model |
| `-cleanup` | `false` | Remove images after processing |
| `-no-ai` | `false` | Skip AI analysis |

### Environment Variables
- `GEMINI_USE_VERTEX_AI`: `false` for Gemini API, `true`/unset for Vertex AI
- `GEMINI_API_KEY`: API key (Gemini API backend)
- `GEMINI_GCP_PROJECT`: GCP project (Vertex AI backend)

## Documentation Index

| File | Topic |
|------|-------|
| `.agent_docs/golang.md` | Go coding standards for this project |
