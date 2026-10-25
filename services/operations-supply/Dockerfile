# Build context = repository root:  docker build -f services/operations-supply/Dockerfile .
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src
COPY shared/Hims.Common/Hims.Common.csproj shared/Hims.Common/
COPY services/operations-supply/Hims.OperationsSupply.csproj services/operations-supply/
RUN dotnet restore services/operations-supply/Hims.OperationsSupply.csproj
COPY shared/ shared/
COPY services/operations-supply/ services/operations-supply/
RUN dotnet publish services/operations-supply/Hims.OperationsSupply.csproj -c Release -o /app --no-restore

FROM mcr.microsoft.com/dotnet/aspnet:8.0
WORKDIR /app
COPY --from=build /app .
ENV ASPNETCORE_URLS=http://+:8080
EXPOSE 8080
ENTRYPOINT ["dotnet", "Hims.OperationsSupply.dll"]
