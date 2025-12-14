package main

import (
	"fmt"
	"image"
	"image/png"
	"os"
	"path/filepath"
	"strings"

	"github.com/gen2brain/go-fitz"
)

// extractPDFContent extracts text and images from a PDF file
func extractPDFContent(pdfPath, outputDir, projectID, region, model string, cleanup, noAI bool) (*ExtractionResult, error) {
	doc, err := openPDF(pdfPath)
	if err != nil {
		return nil, err
	}
	defer doc.Close()

	outputDir, err = prepareOutputDirectory(pdfPath, outputDir)
	if err != nil {
		return nil, err
	}

	imagesDir := filepath.Join(outputDir, "images")
	if err := os.MkdirAll(imagesDir, dirPermissions); err != nil {
		return nil, fmt.Errorf("failed to create images directory: %w", err)
	}

	text, images, err := processPages(doc, imagesDir, projectID, region, model, noAI)
	if err != nil {
		return nil, err
	}

	markdown := createMarkdownOutput(text, images, filepath.Base(pdfPath))
	markdownFile, err := saveMarkdown(outputDir, markdown)
	if err != nil {
		return nil, err
	}

	if cleanup {
		cleanupImages(imagesDir)
	}

	return &ExtractionResult{
		Markdown:     markdown,
		Text:         text,
		Images:       images,
		OutputDir:    outputDir,
		MarkdownFile: markdownFile,
		PDFName:      filepath.Base(pdfPath),
	}, nil
}

// openPDF opens a PDF document
func openPDF(pdfPath string) (*fitz.Document, error) {
	doc, err := fitz.New(pdfPath)
	if err != nil {
		return nil, fmt.Errorf("failed to open PDF: %w", err)
	}
	return doc, nil
}

// prepareOutputDirectory creates and returns the output directory path
func prepareOutputDirectory(pdfPath, outputDir string) (string, error) {
	if outputDir == "" {
		baseName := strings.TrimSuffix(filepath.Base(pdfPath), filepath.Ext(pdfPath))
		outputDir = fmt.Sprintf("%s_extraction", baseName)
	}

	if err := os.MkdirAll(outputDir, dirPermissions); err != nil {
		return "", fmt.Errorf("failed to create output directory: %w", err)
	}

	return outputDir, nil
}

// processPages extracts text and images from all pages
func processPages(doc *fitz.Document, imagesDir, projectID, region, model string, noAI bool) (string, []ImageAnalysis, error) {
	var fullText strings.Builder
	var images []ImageAnalysis
	imageCounter := 0

	fmt.Fprintf(os.Stderr, "%s📖 Processing %d pages...%s\n", colorCyan, doc.NumPage(), colorReset)

	for pageNum := 0; pageNum < doc.NumPage(); pageNum++ {
		fmt.Fprintf(os.Stderr, "%s   Processing page %d/%d...%s\r", colorCyan, pageNum+1, doc.NumPage(), colorReset)

		text, err := extractPageText(doc, pageNum)
		if err != nil {
			return "", nil, err
		}
		fullText.WriteString(text)
		fullText.WriteString("\n\n")

		pageImages, counter, err := extractPageImages(doc, pageNum, imageCounter, imagesDir, projectID, region, model, noAI)
		if err != nil {
			return "", nil, err
		}
		images = append(images, pageImages...)
		imageCounter = counter
	}

	fmt.Fprintf(os.Stderr, "\n")
	return fullText.String(), images, nil
}

// extractPageText extracts text from a single page
func extractPageText(doc *fitz.Document, pageNum int) (string, error) {
	text, err := doc.Text(pageNum)
	if err != nil {
		return "", fmt.Errorf("failed to extract text from page %d: %w", pageNum+1, err)
	}
	return text, nil
}

// extractPageImages extracts images from a single page
func extractPageImages(doc *fitz.Document, pageNum, imageCounter int, imagesDir, projectID, region, model string, noAI bool) ([]ImageAnalysis, int, error) {
	var images []ImageAnalysis

	img, err := doc.Image(pageNum)
	if err != nil || img == nil {
		return images, imageCounter, nil
	}

	imageCounter++
	imageName := fmt.Sprintf("page_%d_image_%d.png", pageNum+1, imageCounter)
	imagePath := filepath.Join(imagesDir, imageName)

	if err := saveImageFile(imagePath, img); err != nil {
		return nil, imageCounter, err
	}

	analysis := processImage(imagePath, pageNum+1, imageCounter, projectID, region, model, noAI, imageName)
	images = append(images, analysis)

	return images, imageCounter, nil
}

// saveImageFile saves an image to disk
func saveImageFile(imagePath string, img image.Image) error {
	f, err := os.Create(imagePath)
	if err != nil {
		return fmt.Errorf("failed to create image file: %w", err)
	}
	defer f.Close()

	if err := png.Encode(f, img); err != nil {
		return fmt.Errorf("failed to encode image: %w", err)
	}

	return nil
}

// processImage analyzes an image with AI or creates basic analysis
func processImage(imagePath string, pageNum, imageNum int, projectID, region, model string, noAI bool, imageName string) ImageAnalysis {
	if noAI {
		return createBasicAnalysis(imagePath, pageNum, imageNum, msgAnalysisSkipped, msgTypeImage)
	}

	analysis, err := analyzeImageWithAI(imagePath, pageNum, imageNum, projectID, region, model)
	if err != nil {
		fmt.Fprintf(os.Stderr, "\n%s⚠️  AI analysis failed for %s: %v%s\n", colorRed, imageName, err, colorReset)
		return createBasicAnalysis(imagePath, pageNum, imageNum, msgAnalysisUnavailable, msgTypeUnknown)
	}

	return analysis
}

// createBasicAnalysis creates a basic ImageAnalysis without AI
func createBasicAnalysis(imagePath string, pageNum, imageNum int, description, imageType string) ImageAnalysis {
	return ImageAnalysis{
		ImagePath:   imagePath,
		PageNumber:  pageNum,
		ImageNumber: imageNum,
		Description: description,
		Type:        imageType,
		Caption:     "",
	}
}

// saveMarkdown saves markdown content to a file
func saveMarkdown(outputDir, markdown string) (string, error) {
	markdownFile := filepath.Join(outputDir, "extracted_content.md")
	if err := os.WriteFile(markdownFile, []byte(markdown), filePermissions); err != nil {
		return "", fmt.Errorf("failed to write markdown file: %w", err)
	}
	return markdownFile, nil
}

// cleanupImages removes the images directory
func cleanupImages(imagesDir string) {
	fmt.Fprintf(os.Stderr, "%s🧹 Cleaning up image files...%s\n", colorCyan, colorReset)
	if err := os.RemoveAll(imagesDir); err != nil {
		fmt.Fprintf(os.Stderr, "%s⚠️  Failed to cleanup images: %v%s\n", colorRed, err, colorReset)
	}
}
