# Build context = repository root:  docker build -f services/patient-engagement/Dockerfile .
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src
COPY shared/Hims.Common/Hims.Common.csproj shared/Hims.Common/
COPY services/patient-engagement/Hims.PatientEngagement.csproj services/patient-engagement/
RUN dotnet restore services/patient-engagement/Hims.PatientEngagement.csproj
COPY shared/ shared/
COPY services/patient-engagement/ services/patient-engagement/
RUN dotnet publish services/patient-engagement/Hims.PatientEngagement.csproj -c Release -o /app --no-restore

FROM mcr.microsoft.com/dotnet/aspnet:8.0
WORKDIR /app
COPY --from=build /app .
ENV ASPNETCORE_URLS=http://+:8080
EXPOSE 8080
ENTRYPOINT ["dotnet", "Hims.PatientEngagement.dll"]
