FROM pytorch/pytorch:1.1.0-cuda10.0-cudnn7.5-devel

RUN apt update && apt install -y vim libglib2.0-0 libsm6 libxext6 libxrender-dev

COPY requirements.txt /workspace/HRNet-Semantic-Segmentation/
RUN pip install -r /workspace/HRNet-Semantic-Segmentation/requirements.txt

COPY data/pascal_ctx/ /workspace/HRNet-Semantic-Segmentation/data/pascal_ctx/
RUN cd /workspace/HRNet-Semantic-Segmentation/data/pascal_ctx/PythonAPI && make && make install

WORKDIR /workspace
