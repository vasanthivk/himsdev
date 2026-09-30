# Build context = repository root:  docker build -f services/back-office/Dockerfile .
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src
COPY shared/Hims.Common/Hims.Common.csproj shared/Hims.Common/
COPY services/back-office/Hims.BackOffice.csproj services/back-office/
RUN dotnet restore services/back-office/Hims.BackOffice.csproj
COPY shared/ shared/
COPY services/back-office/ services/back-office/
RUN dotnet publish services/back-office/Hims.BackOffice.csproj -c Release -o /app --no-restore

FROM mcr.microsoft.com/dotnet/aspnet:8.0
WORKDIR /app
COPY --from=build /app .
ENV ASPNETCORE_URLS=http://+:8080
EXPOSE 8080
ENTRYPOINT ["dotnet", "Hims.BackOffice.dll"]
