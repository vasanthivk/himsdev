# Build context = repository root:  docker build -f services/field-ops/Dockerfile .
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src
COPY shared/Hims.Common/Hims.Common.csproj shared/Hims.Common/
COPY services/field-ops/Hims.FieldOps.csproj services/field-ops/
RUN dotnet restore services/field-ops/Hims.FieldOps.csproj
COPY shared/ shared/
COPY services/field-ops/ services/field-ops/
RUN dotnet publish services/field-ops/Hims.FieldOps.csproj -c Release -o /app --no-restore

FROM mcr.microsoft.com/dotnet/aspnet:8.0
WORKDIR /app
COPY --from=build /app .
ENV ASPNETCORE_URLS=http://+:8080
EXPOSE 8080
ENTRYPOINT ["dotnet", "Hims.FieldOps.dll"]
