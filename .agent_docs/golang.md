# Go Coding Standards - pdf-extractor

## Project Layout

- `cmd/<binary>/main.go` - Minimal CLI entry points
- `internal/<pkg>/` - Private packages (not importable externally)
- `go.mod` at project root (never in `src/`)
- Never use a `/src` directory

## Package Design

- `internal/extractor` - Core extraction logic
  - `types.go` - All exported types (`Config`, `ExtractionResult`, `ImageAnalysis`)
  - `constants.go` - All constants (unexported) + accessor functions for defaults
  - `extractor.go` - Main `Run()` function + PDF processing helpers
  - `ai.go` - Gemini AI integration (client creation, content generation, response parsing)
  - `markdown.go` - Markdown generation from extraction results

## Conventions

### Naming
- Exported types: PascalCase (`Config`, `ExtractionResult`)
- Internal constants: camelCase (`defaultRegion`, `colorGreen`)
- Functions that return defaults: `DefaultRegion()`, `DefaultModel()`

### Error Handling
- Always wrap errors: `fmt.Errorf("context: %w", err)`
- Graceful degradation for AI failures (falls back to basic analysis)
- User-facing errors to stderr with ANSI colors

### Dependencies
- `github.com/gen2brain/go-fitz` - PDF rendering/extraction
- `google.golang.org/genai` - Google Generative AI SDK (supports both Vertex AI and Gemini API)

## Build System

Uses standard template Makefile with `cmd/` auto-detection:
- Builds all binaries found in `cmd/` directory
- Platform-specific binaries in `bin/` with `{name}-{os}-{arch}` naming
- macOS binaries are code-signed automatically
