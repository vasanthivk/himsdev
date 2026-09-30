# Build context = repository root:  docker build -f services/identity-org/Dockerfile .
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src
COPY shared/Hims.Common/Hims.Common.csproj shared/Hims.Common/
COPY services/identity-org/Hims.IdentityOrg.csproj services/identity-org/
RUN dotnet restore services/identity-org/Hims.IdentityOrg.csproj
COPY shared/ shared/
COPY services/identity-org/ services/identity-org/
RUN dotnet publish services/identity-org/Hims.IdentityOrg.csproj -c Release -o /app --no-restore

FROM mcr.microsoft.com/dotnet/aspnet:8.0
WORKDIR /app
COPY --from=build /app .
ENV ASPNETCORE_URLS=http://+:8080
EXPOSE 8080
ENTRYPOINT ["dotnet", "Hims.IdentityOrg.dll"]
