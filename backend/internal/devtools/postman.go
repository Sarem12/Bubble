package postman

import (
	"encoding/json"
	"reflect"
	"strings"
	"sort"

	"github.com/gofiber/fiber/v2"
)

var DtoRegistry = make(map[string]interface{})

func BindDTO(route fiber.Router, dto interface{}) {
	name := reflect.TypeOf(dto).String()
	route.Name("DTO:" + name)
	DtoRegistry[name] = dto
}

func generateDummyJSON(dto interface{}) string {
	val := reflect.New(reflect.TypeOf(dto)).Elem()
	populateDummy(val)
	b, _ := json.MarshalIndent(val.Interface(), "", "  ")
	return string(b)
}

func populateDummy(v reflect.Value) {
	for v.Kind() == reflect.Ptr {
		if v.IsNil() {
			v.Set(reflect.New(v.Type().Elem()))
		}
		v = v.Elem()
	}

	switch v.Kind() {
	case reflect.Struct:
		for i := 0; i < v.NumField(); i++ {
			if v.Type().Field(i).IsExported() {
				populateDummy(v.Field(i))
			}
		}
	case reflect.String:
		v.SetString("string")
	case reflect.Int, reflect.Int8, reflect.Int16, reflect.Int32, reflect.Int64:
		v.SetInt(0)
	case reflect.Float32, reflect.Float64:
		v.SetFloat(0.0)
	case reflect.Bool:
		v.SetBool(true)
	case reflect.Slice:
		slice := reflect.MakeSlice(v.Type(), 1, 1)
		populateDummy(slice.Index(0))
		v.Set(slice)
	}
}

type PostmanURL struct {
	Raw string `json:"raw"`
}

type PostmanBodyOptionsRaw struct {
	Language string `json:"language"`
}

type PostmanBodyOptions struct {
	Raw PostmanBodyOptionsRaw `json:"raw"`
}

type PostmanBody struct {
	Mode    string             `json:"mode"`
	Raw     string             `json:"raw"`
	Options PostmanBodyOptions `json:"options"`
}

type PostmanHeader struct {
	Key   string `json:"key"`
	Value string `json:"value"`
	Type  string `json:"type"`
}

type PostmanReq struct {
	Method      string          `json:"method"`
	URL         string          `json:"url"`
	Description string          `json:"description,omitempty"`
	Header      []PostmanHeader `json:"header"`
	Body        *PostmanBody    `json:"body,omitempty"`
}

type PostmanItem struct {
	Name    string        `json:"name"`
	Request *PostmanReq   `json:"request,omitempty"`
	Item    []PostmanItem `json:"item,omitempty"`
}

type PostmanCollection struct {
	Info struct {
		Name   string `json:"name"`
		Schema string `json:"schema"`
	} `json:"info"`
	Item []PostmanItem `json:"item"`
}

func RegisterPostmanRoute(app *fiber.App, baseURL string) {
	app.Get("/dev/postman", func(c *fiber.Ctx) error {
		col := PostmanCollection{}
		col.Info.Name = "Fiber API"
		col.Info.Schema = "https://schema.getpostman.com/json/collection/v2.1.0/collection.json"

		folderBuckets := make(map[string][]PostmanItem)
		var rootItems []PostmanItem

		for _, route := range app.GetRoutes(true) {
			if route.Method == "HEAD" || route.Path == "/dev/postman" {
				continue
			}

			trimmed := strings.Trim(route.Path, "/")
			parts := strings.Split(trimmed, "/")

			folderName := "General"
			if len(parts) > 1 && parts[0] == "api" {
				if len(parts) > 2 {
					folderName = strings.ToUpper(parts[1]) + " - " + strings.Title(parts[2])
				} else {
					folderName = strings.Title(parts[1])
				}
			} else if len(parts) > 0 && parts[0] != "" {
				folderName = strings.Title(parts[0])
			}

			var body *PostmanBody
			if strings.HasPrefix(route.Name, "DTO:") {
				dtoName := strings.TrimPrefix(route.Name, "DTO:")
				if dto, ok := DtoRegistry[dtoName]; ok {
					body = &PostmanBody{
						Mode: "raw",
						Raw:  generateDummyJSON(dto),
						Options: PostmanBodyOptions{
							Raw: PostmanBodyOptionsRaw{Language: "json"},
						},
					}
				}
			}

			tag := "[WIP]"
			var headers []PostmanHeader
			if body != nil {
				headers = append(headers, PostmanHeader{
					Key:   "Content-Type",
					Value: "application/json",
					Type:  "text",
				})
			} else {
				headers = []PostmanHeader{}
			}
			
			reqItem := PostmanItem{
				Name: tag + " " + route.Method + " " + route.Path,
				Request: &PostmanReq{
					Method:      route.Method,
					URL:         baseURL + route.Path,
					Description: "Status: In Progress\nAuto-exported route.",
					Header:      headers,
					Body:        body,
				},
			}

			folderBuckets[folderName] = append(folderBuckets[folderName], reqItem)
		}

		// Sort folders alphabetically
		var folderNames []string
		for fName := range folderBuckets {
			folderNames = append(folderNames, fName)
		}
		sort.Strings(folderNames)

		for _, fName := range folderNames {
			items := folderBuckets[fName]
			
			// Sort items within folder alphabetically by Name
			sort.Slice(items, func(i, j int) bool {
				return items[i].Name < items[j].Name
			})

			col.Item = append(col.Item, PostmanItem{
				Name: fName,
				Item: items,
			})
		}

		if len(rootItems) > 0 {
			sort.Slice(rootItems, func(i, j int) bool {
				return rootItems[i].Name < rootItems[j].Name
			})
			col.Item = append(col.Item, rootItems...)
		}

		return c.JSON(col)
	})
}
