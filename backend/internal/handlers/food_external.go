package handlers

import (
    "net/http"
    "github.com/gin-gonic/gin"
    "io/ioutil"
    "net/url"
    "os"
)

func SearchUSDAFoods(c *gin.Context) {
    query := c.Query("q")
    if query == "" {
        c.JSON(http.StatusBadRequest, gin.H{"error": "missing q"})
        return
    }
    apiKey := os.Getenv("USDA_API_KEY") 
    base := "https://api.nal.usda.gov/fdc/v1/foods/search"
    params := url.Values{}
    params.Add("api_key", apiKey)
    params.Add("query", query)
    params.Add("pageSize", "12")

    resp, err := http.Get(base + "?" + params.Encode())
    if err != nil {
        c.JSON(http.StatusInternalServerError, gin.H{"error": "usda error"})
        return
    }
    defer resp.Body.Close()
    body, _ := ioutil.ReadAll(resp.Body)
    c.Data(resp.StatusCode, "application/json", body)
}
