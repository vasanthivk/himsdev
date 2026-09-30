# Build context = repository root:  docker build -f services/hospital-ops/Dockerfile .
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src
COPY shared/Hims.Common/Hims.Common.csproj shared/Hims.Common/
COPY services/hospital-ops/Hims.HospitalOps.csproj services/hospital-ops/
RUN dotnet restore services/hospital-ops/Hims.HospitalOps.csproj
COPY shared/ shared/
COPY services/hospital-ops/ services/hospital-ops/
RUN dotnet publish services/hospital-ops/Hims.HospitalOps.csproj -c Release -o /app --no-restore

FROM mcr.microsoft.com/dotnet/aspnet:8.0
WORKDIR /app
COPY --from=build /app .
ENV ASPNETCORE_URLS=http://+:8080
EXPOSE 8080
ENTRYPOINT ["dotnet", "Hims.HospitalOps.dll"]
