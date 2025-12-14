package main

const (
	// Default GCP configuration
	defaultProjectID = "btdp-dta-gbl-0002-gen-ai-01"
	defaultRegion    = "europe-west1"
	defaultModel     = "gemini-1.5-flash"

	// File permissions
	dirPermissions  = 0755
	filePermissions = 0644

	// ANSI color codes for terminal output
	colorGreen = "\033[32m"
	colorRed   = "\033[31m"
	colorCyan  = "\033[36m"
	colorReset = "\033[0m"

	// AI analysis messages
	msgAnalysisUnavailable = "Image analysis unavailable"
	msgAnalysisSkipped     = "AI analysis skipped"
	msgTypeUnknown         = "unknown"
	msgTypeImage           = "image"
)
