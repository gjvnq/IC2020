.PHONY: all docker-build

all: docker-build matsim-0.9.0 otfvis-0.9.0
	docker network create interscity || true
	cd simulator && docker run -it --network interscity --hostname interscity.local -v `pwd`/mock-simulators/smart_city_model/simple_scenario/:/interscsimulator/mock-simulators/smart_city_model/simple_scenario -e CONFIG_PATH=/src/mock-simulators/smart_city_model/base_scenario/config.xml interscitysimulator
docker-build:
	cd simulator && docker build -f mock-simulators/smart_city_model/Dockerfile -t interscitysimulator .

simulator/mock-simulators/smart_city_model/interscsimulator.conf:
	echo "../simple_scenario/config.xml" > $@
matsim-0.9.0: downloads/matsim-0.9.0.zip
	unzip -o downloads/matsim-0.9.0.zip
otfvis-0.9.0: downloads/otfvis-0.9.0.zip
	unzip -o downloads/otfvis-0.9.0.zip
downloads/matsim-0.9.0.zip:
	mkdir -p downloads
	cd downloads && wget https://github.com/matsim-org/matsim-libs/releases/download/matsim-0.9.0/matsim-0.9.0.zip
downloads/otfvis-0.9.0.zip:
	mkdir -p downloads
	cd downloads && wget https://github.com/matsim-org/matsim-libs/releases/download/matsim-0.9.0/otfvis-0.9.0.zip