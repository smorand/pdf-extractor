package main

import (
	"fmt"
	"strings"
)

// createMarkdownOutput generates markdown from extracted content
func createMarkdownOutput(text string, images []ImageAnalysis, pdfName string) string {
	var md strings.Builder

	writeMarkdownHeader(&md, pdfName)
	writeTextContent(&md, text)
	writeImagesSection(&md, images)

	return md.String()
}

// writeMarkdownHeader writes the markdown header
func writeMarkdownHeader(md *strings.Builder, pdfName string) {
	md.WriteString(fmt.Sprintf("# Extracted Content from %s\n\n", pdfName))
}

// writeTextContent writes the text content section
func writeTextContent(md *strings.Builder, text string) {
	md.WriteString("## Text Content\n\n")
	md.WriteString(text)
	md.WriteString("\n\n")
}

// writeImagesSection writes the images section
func writeImagesSection(md *strings.Builder, images []ImageAnalysis) {
	if len(images) == 0 {
		return
	}

	md.WriteString("## Images\n\n")

	for _, img := range images {
		writeImageEntry(md, img)
	}
}

// writeImageEntry writes a single image entry
func writeImageEntry(md *strings.Builder, img ImageAnalysis) {
	md.WriteString(fmt.Sprintf("### Page %d - Image %d\n\n", img.PageNumber, img.ImageNumber))
	md.WriteString(fmt.Sprintf("![%s](%s)\n\n", img.Caption, img.ImagePath))

	if shouldWriteImageType(img.Type) {
		md.WriteString(fmt.Sprintf("**Type:** %s\n\n", img.Type))
	}

	if shouldWriteDescription(img.Description) {
		md.WriteString(fmt.Sprintf("**Description:** %s\n\n", img.Description))
	}

	if shouldWriteCaption(img.Caption) {
		md.WriteString(fmt.Sprintf("**Caption:** %s\n\n", img.Caption))
	}

	md.WriteString("---\n\n")
}

// shouldWriteImageType determines if image type should be written
func shouldWriteImageType(imageType string) bool {
	return imageType != "" && imageType != msgTypeUnknown
}

// shouldWriteDescription determines if description should be written
func shouldWriteDescription(description string) bool {
	return description != "" &&
		description != msgAnalysisSkipped &&
		description != msgAnalysisUnavailable
}

// shouldWriteCaption determines if caption should be written
func shouldWriteCaption(caption string) bool {
	return caption != ""
}
