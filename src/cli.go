package main

import (
	"encoding/json"
	"flag"
	"fmt"
	"os"
)

// CLI represents command-line interface configuration
type CLI struct {
	outputDir string
	projectID string
	region    string
	model     string
	cleanup   bool
	noAI      bool
	pdfPath   string
}

// parseCLI parses command-line arguments and returns CLI configuration
func parseCLI() (*CLI, error) {
	cli := &CLI{}

	flag.StringVar(&cli.outputDir, "output", "", "Output directory for extracted content (default: pdf_name_extraction)")
	flag.StringVar(&cli.projectID, "project", defaultProjectID, "GCP project ID for Vertex AI")
	flag.StringVar(&cli.region, "region", defaultRegion, "GCP region for Vertex AI")
	flag.StringVar(&cli.model, "model", defaultModel, "Vertex AI model to use")
	flag.BoolVar(&cli.cleanup, "cleanup", false, "Clean up image files after processing")
	flag.BoolVar(&cli.noAI, "no-ai", false, "Skip AI image analysis")
	flag.Parse()

	if flag.NArg() < 1 {
		return nil, fmt.Errorf("PDF file path required")
	}

	cli.pdfPath = flag.Arg(0)

	// Validate PDF file exists
	if _, err := os.Stat(cli.pdfPath); os.IsNotExist(err) {
		return nil, fmt.Errorf("PDF file not found: %s", cli.pdfPath)
	}

	return cli, nil
}

// printUsage prints usage information to stderr
func printUsage() {
	fmt.Fprintf(os.Stderr, "%sUsage: pdf-extractor [OPTIONS] <pdf-file>%s\n", colorRed, colorReset)
	fmt.Fprintf(os.Stderr, "\nOptions:\n")
	flag.PrintDefaults()
}

// printResult prints the extraction result as JSON to stdout
func printResult(result *ExtractionResult) error {
	jsonData, err := json.MarshalIndent(result, "", "  ")
	if err != nil {
		return fmt.Errorf("failed to marshal result: %w", err)
	}
	fmt.Println(string(jsonData))
	return nil
}

// printSuccess prints success messages to stderr
func printSuccess(result *ExtractionResult) {
	fmt.Fprintf(os.Stderr, "%s✅ Extraction complete!%s\n", colorGreen, colorReset)
	fmt.Fprintf(os.Stderr, "%s   Output directory: %s%s\n", colorGreen, result.OutputDir, colorReset)
	fmt.Fprintf(os.Stderr, "%s   Markdown file: %s%s\n", colorGreen, result.MarkdownFile, colorReset)
}
