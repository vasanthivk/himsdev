# Build context = repository root:  docker build -f services/pharmacy-supply/Dockerfile .
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src
COPY shared/Hims.Common/Hims.Common.csproj shared/Hims.Common/
COPY services/pharmacy-supply/Hims.PharmacySupply.csproj services/pharmacy-supply/
RUN dotnet restore services/pharmacy-supply/Hims.PharmacySupply.csproj
COPY shared/ shared/
COPY services/pharmacy-supply/ services/pharmacy-supply/
RUN dotnet publish services/pharmacy-supply/Hims.PharmacySupply.csproj -c Release -o /app --no-restore

FROM mcr.microsoft.com/dotnet/aspnet:8.0
WORKDIR /app
COPY --from=build /app .
ENV ASPNETCORE_URLS=http://+:8080
EXPOSE 8080
ENTRYPOINT ["dotnet", "Hims.PharmacySupply.dll"]
