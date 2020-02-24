# Start from golang base image
FROM golang:alpine as builder

# ENV GO111MODULE=on

# Add Maintainer info
LABEL maintainer="kerlexov <kerlexov@gmail.com>"

# Install git.
# Git is required for fetching the dependencies.
RUN apk update && apk add --no-cache git && mkdir /go/src/app

# Set the current working directory inside the container
WORKDIR /go/src/app

RUN go get -u github.com/golang/dep/cmd/dep && go get -u github.com/kerlexov/back_core

# Copy go mod and sum files
ADD Gopkg.* ./

# Download all dependencies. Dependencies will be cached if the go.mod and the go.sum files are not changed
RUN dep ensure -vendor-only

# Copy the source from the current directory to the working Directory inside the container
COPY . .

# Build the Go app
RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o main .

# Start a new stage from scratch
FROM alpine:latest
RUN apk --no-cache add ca-certificates

WORKDIR /root/

# Copy the Pre-built binary file from the previous stage. Observe we also copied the .env file
COPY --from=builder /go/src/app/main .
COPY --from=builder /go/src/app/.env .

# Expose port 420 to the outside world
EXPOSE 420

#Command to run the executable
CMD ["./main"]