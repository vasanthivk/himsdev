# Build context = repository root:  docker build -f services/digital-engagement/Dockerfile .
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src
COPY shared/Hims.Common/Hims.Common.csproj shared/Hims.Common/
COPY services/digital-engagement/Hims.DigitalEngagement.csproj services/digital-engagement/
RUN dotnet restore services/digital-engagement/Hims.DigitalEngagement.csproj
COPY shared/ shared/
COPY services/digital-engagement/ services/digital-engagement/
RUN dotnet publish services/digital-engagement/Hims.DigitalEngagement.csproj -c Release -o /app --no-restore

FROM mcr.microsoft.com/dotnet/aspnet:8.0
WORKDIR /app
COPY --from=build /app .
ENV ASPNETCORE_URLS=http://+:8080
EXPOSE 8080
ENTRYPOINT ["dotnet", "Hims.DigitalEngagement.dll"]
