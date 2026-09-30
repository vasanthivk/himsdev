# Build context = repository root:  docker build -f services/imaging/Dockerfile .
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src
COPY shared/Hims.Common/Hims.Common.csproj shared/Hims.Common/
COPY services/imaging/Hims.Imaging.csproj services/imaging/
RUN dotnet restore services/imaging/Hims.Imaging.csproj
COPY shared/ shared/
COPY services/imaging/ services/imaging/
RUN dotnet publish services/imaging/Hims.Imaging.csproj -c Release -o /app --no-restore

FROM mcr.microsoft.com/dotnet/aspnet:8.0
WORKDIR /app
COPY --from=build /app .
ENV ASPNETCORE_URLS=http://+:8080
EXPOSE 8080
ENTRYPOINT ["dotnet", "Hims.Imaging.dll"]
