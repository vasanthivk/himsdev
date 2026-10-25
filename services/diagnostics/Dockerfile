# Build context = repository root:  docker build -f services/diagnostics/Dockerfile .
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src
COPY shared/Hims.Common/Hims.Common.csproj shared/Hims.Common/
COPY services/diagnostics/Hims.Diagnostics.csproj services/diagnostics/
RUN dotnet restore services/diagnostics/Hims.Diagnostics.csproj
COPY shared/ shared/
COPY services/diagnostics/ services/diagnostics/
RUN dotnet publish services/diagnostics/Hims.Diagnostics.csproj -c Release -o /app --no-restore

FROM mcr.microsoft.com/dotnet/aspnet:8.0
WORKDIR /app
COPY --from=build /app .
ENV ASPNETCORE_URLS=http://+:8080
EXPOSE 8080
ENTRYPOINT ["dotnet", "Hims.Diagnostics.dll"]
