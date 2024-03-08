# 选择你需要的版本
FROM nvidia/cuda:12.3.1-devel-ubuntu22.04

# 更新软件包并安装一些基础工具
RUN apt-get update && apt-get install -y --no-install-recommends \
    wget \
    git \
    vim \
    ssh \
    zsh \
    && rm -rf /var/lib/apt/lists/*

RUN chsh -s $(which zsh)

# 下载Miniconda安装脚本并安装
RUN wget --quiet https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O ~/miniconda.sh && \
    /bin/bash ~/miniconda.sh -b -p /opt/conda && \
    rm ~/miniconda.sh

# 将Conda设置为环境变量
ENV PATH=/opt/conda/bin:$PATH

# 配置SSH服务
RUN mkdir /var/run/sshd
RUN echo 'root:yourpasswd' | chpasswd
# PASSWD yourpasswd
RUN sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config
# 开放22端口
EXPOSE 22

# 设置MOTD
COPY ./lab_22.04.motd ~/.lab_motd

# 安装oh-my-zsh（可选）
RUN git clone https://github.com/ohmyzsh/ohmyzsh.git ~/.oh-my-zsh
RUN cp $HOME/.oh-my-zsh/templates/zshrc.zsh-template ~/.zshrc 

# 修改/root/.bashrc，添加执行.lab_motd的命令
RUN echo 'bash ~/.lab_motd' >> ~/.zshrc

# Add the CUDA environment variables to Zsh's configuration
RUN echo 'export PATH=/usr/local/cuda/bin:$PATH' >> ~/.zshrc \
    && echo 'export LD_LIBRARY_PATH=/usr/local/cuda/lib64:$LD_LIBRARY_PATH' >> ~/.zshrc \
    && echo 'export LIBRARY_PATH=/usr/local/cuda/lib64:$LIBRARY_PATH' >> ~/.zshrc


# 安装powerlevel10k主题
RUN git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k
# 设置Zsh主题为powerlevel10k
RUN sed -i 's/ZSH_THEME="robbyrussell"/ZSH_THEME="powerlevel10k\/powerlevel10k"/g' ~/.zshrc
# 安装zsh-autosuggestions插件
RUN git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
# 安装zsh-syntax-highlighting插件
RUN git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
# 启用插件
RUN sed -i 's/plugins=(git)/plugins=(git zsh-autosuggestions zsh-syntax-highlighting)/g' ~/.zshrc

RUN cp ./p10k.zsh ~/.p10k.zsh && \
    echo "\n# To customize prompt, run \`p10k configure\` or edit ~/.p10k.zsh.\n[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh" >> ~/.zshrc && \
    rm -rf ~/LAB_docker

RUN conda init zsh

# 创建docker-entrypoint.sh脚本
RUN echo '#!/bin/bash' > /usr/local/bin/docker-entrypoint.sh && \
    echo '/usr/sbin/sshd -D &' >> /usr/local/bin/docker-entrypoint.sh && \
    echo 'exec "$@"' >> /usr/local/bin/docker-entrypoint.sh
# 给予脚本执行权限
RUN chmod +x /usr/local/bin/docker-entrypoint.sh
# 设置容器入口点为docker-entrypoint.sh脚本
ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]

# 如果没有提供其他命令，则默认执行zsh
CMD ["/bin/zsh"]
