package main

import (
	"fmt"
	"os"
)

func main() {
	cli, err := parseCLI()
	if err != nil {
		printUsage()
		fmt.Fprintf(os.Stderr, "%s❌ Error: %v%s\n", colorRed, err, colorReset)
		os.Exit(1)
	}

	fmt.Fprintf(os.Stderr, "%s📄 Extracting PDF: %s%s\n", colorCyan, cli.pdfPath, colorReset)

	result, err := extractPDFContent(
		cli.pdfPath,
		cli.outputDir,
		cli.projectID,
		cli.region,
		cli.model,
		cli.cleanup,
		cli.noAI,
	)
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
