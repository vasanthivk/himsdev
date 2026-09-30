# Build context = repository root:  docker build -f services/revenue-cycle/Dockerfile .
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src
COPY shared/Hims.Common/Hims.Common.csproj shared/Hims.Common/
COPY services/revenue-cycle/Hims.RevenueCycle.csproj services/revenue-cycle/
RUN dotnet restore services/revenue-cycle/Hims.RevenueCycle.csproj
COPY shared/ shared/
COPY services/revenue-cycle/ services/revenue-cycle/
RUN dotnet publish services/revenue-cycle/Hims.RevenueCycle.csproj -c Release -o /app --no-restore

FROM mcr.microsoft.com/dotnet/aspnet:8.0
WORKDIR /app
COPY --from=build /app .
ENV ASPNETCORE_URLS=http://+:8080
EXPOSE 8080
ENTRYPOINT ["dotnet", "Hims.RevenueCycle.dll"]
