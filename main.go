package main

import (
	"encoding/base64"
	"net/http"
	"os"

	"github.com/gin-gonic/gin"
)

type Input struct {
	Text string `json:"text" binding:"required"`
}

// limitBody rejects request bodies larger than 64 KB.
func limitBody() gin.HandlerFunc {
	return func(c *gin.Context) {
		c.Request.Body = http.MaxBytesReader(c.Writer, c.Request.Body, 64<<10)
		c.Next()
	}
}

func main() {
	r := gin.Default()
	r.Use(limitBody())

	r.GET("/health", func(c *gin.Context) {
		c.String(http.StatusOK, "ok")
	})

	api := r.Group("/api")

	api.POST("/encode", func(c *gin.Context) {
		var in Input
		if err := c.ShouldBindJSON(&in); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
			return
		}
		c.JSON(http.StatusOK, gin.H{
			"result": base64.StdEncoding.EncodeToString([]byte(in.Text)),
		})
	})

	api.POST("/decode", func(c *gin.Context) {
		var in Input
		if err := c.ShouldBindJSON(&in); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
			return
		}
		data, err := base64.StdEncoding.DecodeString(in.Text)
		if err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "invalid base64"})
			return
		}
		c.JSON(http.StatusOK, gin.H{"result": string(data)})
	})

	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}
	r.Run(":" + port)
}
