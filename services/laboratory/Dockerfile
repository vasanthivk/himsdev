# Build context = repository root:  docker build -f services/laboratory/Dockerfile .
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src
COPY shared/Hims.Common/Hims.Common.csproj shared/Hims.Common/
COPY services/laboratory/Hims.Laboratory.csproj services/laboratory/
RUN dotnet restore services/laboratory/Hims.Laboratory.csproj
COPY shared/ shared/
COPY services/laboratory/ services/laboratory/
RUN dotnet publish services/laboratory/Hims.Laboratory.csproj -c Release -o /app --no-restore

FROM mcr.microsoft.com/dotnet/aspnet:8.0
WORKDIR /app
COPY --from=build /app .
ENV ASPNETCORE_URLS=http://+:8080
EXPOSE 8080
ENTRYPOINT ["dotnet", "Hims.Laboratory.dll"]
