package main

// ExtractionResult contains the complete result of PDF extraction
type ExtractionResult struct {
	Markdown     string          `json:"markdown"`
	Text         string          `json:"text"`
	Images       []ImageAnalysis `json:"images"`
	OutputDir    string          `json:"output_dir"`
	MarkdownFile string          `json:"markdown_file"`
	PDFName      string          `json:"pdf_name"`
}

// ImageAnalysis contains AI-generated analysis of an extracted image
type ImageAnalysis struct {
	ImagePath   string `json:"image_path"`
	PageNumber  int    `json:"page_number"`
	ImageNumber int    `json:"image_number"`
	Description string `json:"description"`
	Type        string `json:"type"`
	Caption     string `json:"caption"`
}
