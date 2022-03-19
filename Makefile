EXECUTABLE=monaco

.PHONY: lint format mocks build install clean test integration-test test-package default add-license-headers

default: build

lint:
ifeq ($(OS),Windows_NT)
	@.\tools\check-format.cmd
else
	@go get github.com/google/addlicense
	@sh ./tools/check-format.sh
	@sh ./tools/check-license-headers.sh
endif

format:
	@gofmt -w .

add-license-headers:
ifeq ($(OS),Windows_NT)
	@echo "This is currently not supported on windows"
	@exit 1
else
	@sh ./tools/add-missing-license-headers.sh
endif

mocks:
	@go get github.com/golang/mock/mockgen
	@go generate ./...

build: clean lint
	GOOS=windows GOARCH=amd64 go build -o ./bin/${EXECUTABLE}-windows-amd64.exe ./cmd/monaco
	GOOS=windows GOARCH=386 go build -o ./bin/${EXECUTABLE}-windows-386.exe ./cmd/monaco
	GOOS=linux GOARCH=amd64 go build -o ./bin/${EXECUTABLE}-linux-amd64 ./cmd/monaco
	GOOS=linux GOARCH=386 go build -o ./bin/${EXECUTABLE}-linux-386 ./cmd/monaco
	GOOS=darwin GOARCH=amd64 go build -o ./bin/${EXECUTABLE}-darwin-amd64 ./cmd/monaco
	GOOS=darwin GOARCH=arm64 go build -o ./bin/${EXECUTABLE}-darwin-386 ./cmd/monaco

install: clean lint
	@echo Install ${EXECUTABLE}
	@go install ./...

clean:
	@echo Remove bin/
ifeq ($(OS),Windows_NT)
	@if exist bin rd /S /Q bin
else
	@rm -rf bin/
endif

test: mocks build
	@go test -tags=unit -v ./...

integration-test: build
	@go test -tags=cleanup -v ./...
	@go test -tags=integration -v ./...

# Build and Test a single package supplied via pgk variable, without using test cache
# Run as e.g. make test-package pkg=project
pkg=...
test-package: mocks build
	@go test -tags=unit -count=1 -v ./pkg/${pkg}
