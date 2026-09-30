# Build context = repository root:  docker build -f services/clinical-care/Dockerfile .
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src
COPY shared/Hims.Common/Hims.Common.csproj shared/Hims.Common/
COPY services/clinical-care/Hims.ClinicalCare.csproj services/clinical-care/
RUN dotnet restore services/clinical-care/Hims.ClinicalCare.csproj
COPY shared/ shared/
COPY services/clinical-care/ services/clinical-care/
RUN dotnet publish services/clinical-care/Hims.ClinicalCare.csproj -c Release -o /app --no-restore

FROM mcr.microsoft.com/dotnet/aspnet:8.0
WORKDIR /app
COPY --from=build /app .
ENV ASPNETCORE_URLS=http://+:8080
EXPOSE 8080
ENTRYPOINT ["dotnet", "Hims.ClinicalCare.dll"]
