# Build context = repository root:  docker build -f services/comms-docs/Dockerfile .
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src
COPY shared/Hims.Common/Hims.Common.csproj shared/Hims.Common/
COPY services/comms-docs/Hims.CommsDocs.csproj services/comms-docs/
RUN dotnet restore services/comms-docs/Hims.CommsDocs.csproj
COPY shared/ shared/
COPY services/comms-docs/ services/comms-docs/
RUN dotnet publish services/comms-docs/Hims.CommsDocs.csproj -c Release -o /app --no-restore

FROM mcr.microsoft.com/dotnet/aspnet:8.0
WORKDIR /app
COPY --from=build /app .
ENV ASPNETCORE_URLS=http://+:8080
EXPOSE 8080
ENTRYPOINT ["dotnet", "Hims.CommsDocs.dll"]
