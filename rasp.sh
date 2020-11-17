#! /bin/bash
# script to install/create an environment for ReAgent in CentOS 8 (no GPU)
# based on https://github.com/facebookresearch/ReAgent/blob/master/docs/installation.rst

# installing git and other packages (development, utilities).
sudo yum install git gcc openssl-devel bzip2-devel libffi-devel zlib-devel wget cmake unzip -y
sudo yum groupinstall "Development Tools" -y

# installing miniconda (with the latest python 3, currently 3.8.3)
wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh
bash Miniconda3-latest-Linux-x86_64.sh -b -p $HOME/miniconda
rm Miniconda3-latest-Linux-x86_64.sh
export PATH=$HOME/miniconda/bin:$PATH

# creating python3.7 environment because currently some dependent pypi packages for ReAgent do not install under python3.8.
conda create -n reagent python=3.7 -y
source activate reagent

# installing ReAgent and its dependent packages
git clone https://github.com/facebookresearch/ReAgent.git
cd ReAgent
pip install ".[gym]"

# installing nightly torch (change cpu to cu101/102 if fit)
pip install --pre torch torchvision -f https://download.pytorch.org/whl/nightly/cpu/torch_nightly.html --use-feature=2020-resolver

# verifying the setup (can be skipped in the script; taking >> 20 mins)
#pip install tox
#tox

# installing Scala, maven for spark JAR
curl -s "https://get.sdkman.io" | bash
source "$HOME/.sdkman/bin/sdkman-init.sh"
sdk install scala
sdk install maven

# installing spark
sdk install spark 2.4.6

# building preprocessing JAR
mvn -f preprocessing/pom.xml clean package

# installing requirements for RASP
conda install --file rasp_requirements.txt -y

# installing lib torch (for cuda 10.2)
#wget https://download.pytorch.org/libtorch/nightly/cu102/libtorch-cxx11-abi-shared-with-deps-latest.zip
# installing lib torch (for no cuda)
wget https://download.pytorch.org/libtorch/nightly/cpu/libtorch-cxx11-abi-shared-with-deps-latest.zip 
unzip libtorch-cxx11-abi-shared-with-deps-latest.zip -d $HOME
rm libtorch-cxx11-abi-shared-with-deps-latest.zip

# init git submodules
git submodule update --force --recursive --init --remote

# building RASP
mkdir -p serving/build
cd serving/build
cmake -DCMAKE_PREFIX_PATH=$HOME/libtorch -DCMAKE_CXX_STANDARD=17 ..
make
