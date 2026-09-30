# Build context = repository root:  docker build -f services/patient-access/Dockerfile .
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src
COPY shared/Hims.Common/Hims.Common.csproj shared/Hims.Common/
COPY services/patient-access/Hims.PatientAccess.csproj services/patient-access/
RUN dotnet restore services/patient-access/Hims.PatientAccess.csproj
COPY shared/ shared/
COPY services/patient-access/ services/patient-access/
RUN dotnet publish services/patient-access/Hims.PatientAccess.csproj -c Release -o /app --no-restore

FROM mcr.microsoft.com/dotnet/aspnet:8.0
WORKDIR /app
COPY --from=build /app .
ENV ASPNETCORE_URLS=http://+:8080
EXPOSE 8080
ENTRYPOINT ["dotnet", "Hims.PatientAccess.dll"]
