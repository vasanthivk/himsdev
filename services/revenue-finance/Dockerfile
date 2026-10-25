# Build context = repository root:  docker build -f services/revenue-finance/Dockerfile .
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src
COPY shared/Hims.Common/Hims.Common.csproj shared/Hims.Common/
COPY services/revenue-finance/Hims.RevenueFinance.csproj services/revenue-finance/
RUN dotnet restore services/revenue-finance/Hims.RevenueFinance.csproj
COPY shared/ shared/
COPY services/revenue-finance/ services/revenue-finance/
RUN dotnet publish services/revenue-finance/Hims.RevenueFinance.csproj -c Release -o /app --no-restore

FROM mcr.microsoft.com/dotnet/aspnet:8.0
WORKDIR /app
COPY --from=build /app .
ENV ASPNETCORE_URLS=http://+:8080
EXPOSE 8080
ENTRYPOINT ["dotnet", "Hims.RevenueFinance.dll"]
