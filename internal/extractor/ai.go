package extractor

import (
	"context"
	"encoding/json"
	"fmt"
	"os"
	"strings"

	"google.golang.org/genai"
)

const aiPrompt = `Analyze this image and provide:
1. A detailed description of what the image shows
2. The type of image (e.g., diagram, chart, photograph, illustration, screenshot, table)
3. A suggested caption for the image

Respond in JSON format:
{
  "description": "detailed description",
  "type": "image type",
  "caption": "suggested caption"
}`

// aiResponse represents the expected AI response structure
type aiResponse struct {
	Description string `json:"description"`
	Type        string `json:"type"`
	Caption     string `json:"caption"`
}

// analyzeImageWithAI uses Gemini AI to analyze an image
func analyzeImageWithAI(imagePath string, pageNum, imageNum int, region, model string) (ImageAnalysis, error) {
	ctx := context.Background()

	cfg := getAIConfig(region)
	client, err := createAIClient(ctx, cfg)
	if err != nil {
		return ImageAnalysis{}, err
	}

	imageData, err := os.ReadFile(imagePath)
	if err != nil {
		return ImageAnalysis{}, fmt.Errorf("failed to read image: %w", err)
	}

	responseText, err := generateAIContent(ctx, client, model, imageData)
	if err != nil {
		return ImageAnalysis{}, err
	}

	return parseAIResponse(responseText, imagePath, pageNum, imageNum)
}

// aiConfig holds the AI backend configuration
type aiConfig struct {
	useVertexAI bool
	apiKey      string
	projectID   string
	region      string
}

// getAIConfig reads AI configuration from environment variables
func getAIConfig(region string) aiConfig {
	useVertexAI := true
	if v := os.Getenv(envUseVertexAI); v == "false" || v == "0" {
		useVertexAI = false
	}

	return aiConfig{
		useVertexAI: useVertexAI,
		apiKey:      os.Getenv(envAPIKey),
		projectID:   os.Getenv(envGCPProject),
		region:      region,
	}
}

// createAIClient creates a new Gemini client based on configuration
func createAIClient(ctx context.Context, cfg aiConfig) (*genai.Client, error) {
	if cfg.useVertexAI {
		if cfg.projectID == "" {
			return nil, fmt.Errorf("GEMINI_GCP_PROJECT environment variable required for Vertex AI backend")
		}
		client, err := genai.NewClient(ctx, &genai.ClientConfig{
			Project:  cfg.projectID,
			Location: cfg.region,
			Backend:  genai.BackendVertexAI,
		})
		if err != nil {
			return nil, fmt.Errorf("failed to create Vertex AI client: %w", err)
		}
		return client, nil
	}

	// Gemini API (generativelanguage API) backend
	if cfg.apiKey == "" {
		return nil, fmt.Errorf("GEMINI_API_KEY environment variable required for Gemini API backend")
	}
	client, err := genai.NewClient(ctx, &genai.ClientConfig{
		APIKey:  cfg.apiKey,
		Backend: genai.BackendGeminiAPI,
	})
	if err != nil {
		return nil, fmt.Errorf("failed to create Gemini API client: %w", err)
	}
	return client, nil
}

// generateAIContent generates content using the AI model
func generateAIContent(ctx context.Context, client *genai.Client, model string, imageData []byte) (string, error) {
	resp, err := client.Models.GenerateContent(ctx, model,
		[]*genai.Content{
			genai.NewContentFromText(aiPrompt, genai.RoleUser),
			genai.NewContentFromBytes(imageData, "image/png", genai.RoleUser),
		},
		nil,
	)
	if err != nil {
		return "", fmt.Errorf("failed to generate content: %w", err)
	}

	return extractResponseText(resp)
}

// extractResponseText extracts text from AI response
func extractResponseText(resp *genai.GenerateContentResponse) (string, error) {
	if len(resp.Candidates) == 0 || resp.Candidates[0].Content == nil || len(resp.Candidates[0].Content.Parts) == 0 {
		return "", fmt.Errorf("no response from AI model")
	}

	var responseText strings.Builder
	for _, part := range resp.Candidates[0].Content.Parts {
		if part.Text != "" {
			responseText.WriteString(part.Text)
		}
	}

	return responseText.String(), nil
}

// parseAIResponse parses the AI response and creates ImageAnalysis
func parseAIResponse(responseText, imagePath string, pageNum, imageNum int) (ImageAnalysis, error) {
	cleanedText := cleanJSONResponse(responseText)

	var response aiResponse
	if err := json.Unmarshal([]byte(cleanedText), &response); err != nil {
		// If JSON parsing fails, use raw response as description
		return ImageAnalysis{
			ImagePath:   imagePath,
			PageNumber:  pageNum,
			ImageNumber: imageNum,
			Description: cleanedText,
			Type:        msgTypeUnknown,
			Caption:     "",
		}, nil
	}

	return ImageAnalysis{
		ImagePath:   imagePath,
		PageNumber:  pageNum,
		ImageNumber: imageNum,
		Description: response.Description,
		Type:        response.Type,
		Caption:     response.Caption,
	}, nil
}

// cleanJSONResponse removes markdown code blocks from response
func cleanJSONResponse(text string) string {
	cleaned := text
	cleaned = strings.TrimPrefix(cleaned, "```json\n")
	cleaned = strings.TrimPrefix(cleaned, "```\n")
	cleaned = strings.TrimSuffix(cleaned, "\n```")
	cleaned = strings.TrimSpace(cleaned)
	return cleaned
}
