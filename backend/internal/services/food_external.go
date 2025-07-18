package services

import (
	"encoding/json"
	"fmt"
	"net/http"
	"net/url"
	"os"
	"time"
)

type USDFood struct {
	Description string `json:"description"`
	FdcID       int    `json:"fdcId"`

	FoodNutrients []struct {
		Name  string      `json:"nutrientName"`
		Value interface{} `json:"value"`
		Unit  string      `json:"unitName"`
	} `json:"foodNutrients"`
}

type USDAFoodSearchResponse struct {
	Foods []USDFood `json:"foods"`
}

func SearchUSDAFoods(query string) ([]USDFood, error) {
	apiKey := os.Getenv("USDA_API_KEY")
	endpoint := "https://api.nal.usda.gov/fdc/v1/foods/search"
	params := url.Values{}
	params.Set("api_key", apiKey)
	params.Set("query", query)
	params.Set("pageSize", "20")

	reqUrl := fmt.Sprintf("%s?%s", endpoint, params.Encode())
	req, _ := http.NewRequest("GET", reqUrl, nil)
	req.Header.Set("Accept", "application/json")
	client := &http.Client{Timeout: 8 * time.Second}

	resp, err := client.Do(req)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()

	var result USDAFoodSearchResponse
	if err := json.NewDecoder(resp.Body).Decode(&result); err != nil {
		return nil, err
	}
	return result.Foods, nil
}
