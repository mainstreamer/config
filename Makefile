build:
	@echo "building..."
	@sed -i.bak '$$s/.*/#Built $(shell date)/' ./mc/zsh/.zshrc
	@cd ./mc/zsh && tar -cvzf ../../cfgmc.tar.gz .zshrc .zshrc.d/
	@cd ./../../
	@echo "Done! To install type:"
	@echo "tar -xvzf `pwd`/cfgmc.tar.gz"
