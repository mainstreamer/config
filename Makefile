build:
	@echo "building..."
	@sed -i.bak '$$s/.*/#Built $(shell date)/' ./mc/zsh/.zshrc
	@cd ./mc/zsh && tar -cvzf ../../cfgmc.tar.gz .zshrc .zshrc.d/
	@cd ./../../
	@echo "Done! To install type:"
	@echo "tar -xvzf `pwd`/cfgmc.tar.gz"

build-lx:
	@echo "building..."
	@sed -i.bak '$$s/.*/#Built $(shell date)/' ./lx/bash/.bashrc
	@cd ./lx/bash && tar -cvzf ../../cfglx.tar.gz .bashrc .bashrc.d/
	@cd ./../../
	@echo "Done! To install type:"
	@echo "tar -xvzf `pwd`/cfglx.tar.gz"

i-lx:
	@echo "installing linux bash profile..."
	@tar -xvzf `pwd`/cfglx.tar.gz -C ~/
	@echo "done"
