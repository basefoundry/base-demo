FROM golang:1.21-alpine AS build

WORKDIR /src
COPY go.mod ./
COPY *.go ./
RUN CGO_ENABLED=0 GOOS=linux go build -o /out/go-api .

FROM gcr.io/distroless/static-debian12:nonroot

COPY --from=build /out/go-api /go-api
EXPOSE 8010
USER nonroot:nonroot
ENTRYPOINT ["/go-api"]
