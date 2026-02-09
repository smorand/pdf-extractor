package main

import (
	"encoding/json"
	"flag"
	"fmt"
	"os"

	"pdf-extractor/internal/extractor"
)

const (
	colorGreen = "\033[32m"
	colorRed   = "\033[31m"
	colorCyan  = "\033[36m"
	colorReset = "\033[0m"
)

func main() {
	cfg, err := parseCLI()
	if err != nil {
		printUsage()
		fmt.Fprintf(os.Stderr, "%s❌ Error: %v%s\n", colorRed, err, colorReset)
		os.Exit(1)
	}

	fmt.Fprintf(os.Stderr, "%s📄 Extracting PDF: %s%s\n", colorCyan, cfg.PDFPath, colorReset)

	result, err := extractor.Run(cfg)
	if err != nil {
		fmt.Fprintf(os.Stderr, "%s❌ Error: %v%s\n", colorRed, err, colorReset)
		os.Exit(1)
	}

	if err := printResult(result); err != nil {
		fmt.Fprintf(os.Stderr, "%s❌ Error: %v%s\n", colorRed, err, colorReset)
		os.Exit(1)
	}

	printSuccess(result)
}

// parseCLI parses command-line arguments and returns extractor configuration
func parseCLI() (extractor.Config, error) {
	var cfg extractor.Config

	flag.StringVar(&cfg.OutputDir, "output", "", "Output directory for extracted content (default: pdf_name_extraction)")
	flag.StringVar(&cfg.Region, "region", extractor.DefaultRegion(), "GCP region for Vertex AI (only used with Vertex AI backend)")
	flag.StringVar(&cfg.Model, "model", extractor.DefaultModel(), "Gemini model to use")
	flag.BoolVar(&cfg.Cleanup, "cleanup", false, "Clean up image files after processing")
	flag.BoolVar(&cfg.NoAI, "no-ai", false, "Skip AI image analysis")
	flag.Parse()

	if flag.NArg() < 1 {
		return cfg, fmt.Errorf("PDF file path required")
	}

	cfg.PDFPath = flag.Arg(0)

	if _, err := os.Stat(cfg.PDFPath); os.IsNotExist(err) {
		return cfg, fmt.Errorf("PDF file not found: %s", cfg.PDFPath)
	}

	return cfg, nil
}

// printUsage prints usage information to stderr
func printUsage() {
	fmt.Fprintf(os.Stderr, "%sUsage: pdf-extractor [OPTIONS] <pdf-file>%s\n", colorRed, colorReset)
	fmt.Fprintf(os.Stderr, "\nOptions:\n")
	flag.PrintDefaults()
}

// printResult prints the extraction result as JSON to stdout
func printResult(result *extractor.ExtractionResult) error {
	jsonData, err := json.MarshalIndent(result, "", "  ")
	if err != nil {
		return fmt.Errorf("failed to marshal result: %w", err)
	}
	fmt.Println(string(jsonData))
	return nil
}

// printSuccess prints success messages to stderr
func printSuccess(result *extractor.ExtractionResult) {
	fmt.Fprintf(os.Stderr, "%s✅ Extraction complete!%s\n", colorGreen, colorReset)
	fmt.Fprintf(os.Stderr, "%s   Output directory: %s%s\n", colorGreen, result.OutputDir, colorReset)
	fmt.Fprintf(os.Stderr, "%s   Markdown file: %s%s\n", colorGreen, result.MarkdownFile, colorReset)
}
