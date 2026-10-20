#---Stage 1: Build---
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build 
WORKDIR /src
COPY *.csproj ./
RUN dotnet restore 
COPY . . 
RUN dotnet publish -c Release -o /app/publish --no-restore  /p:UseAppHost=false 

#--- Stage 2: runtime --- 
FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS runtime 
WORKDIR /app
RUN apt-get update \
 && apt-get install -y --only-upgrade perl-base \
 && rm -rf /var/lib/apt/lists/*
RUN adduser --disabled-password --gecos "" appuser 
COPY --from=build --chown=appuser:appuser  /app/publish . 
USER appuser 
EXPOSE 8080 
ENTRYPOINT ["dotnet", "OrderService.dll"]
