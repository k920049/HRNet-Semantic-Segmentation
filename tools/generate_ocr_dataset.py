import os

def main():
    annotation_path = "../data/annotations"
    image_path = "../data/rimages"
    volume_path = "/dltraining/datasets/ocr/"

    image_list = os.listdir(image_path)
    annotation_list = os.listdir(annotation_path)

    split_ratio = 0.8
    train_list = image_list[0:int(len(image_list) * split_ratio)]
    test_list = image_list[int(len(image_list) * split_ratio):]

    annotations = dict()
    for instance in annotation_list:
        name, extension = instance.split(".")
        annotations[name] = extension

    with open("../data/list/ocr/train.lst", "w+") as f:
        for idx, instance in enumerate(train_list):
            name, extension = instance.split(".")
            if name in annotations:
                image = os.path.join(volume_path, "rimage", instance)
                label = os.path.join(volume_path, "annotations", name + "." + annotations[name])
                f.write(image + " " + label + "\n")

    with open("../data/list/ocr/val.lst", "w+") as f:
        for idx, instance in enumerate(test_list):
            name, extension = instance.split(".")
            if name in annotations:
                image = os.path.join(volume_path, "rimage", instance)
                label = os.path.join(volume_path, "annotations", name + "." + annotations[name])
                f.write(image + " " + label + "\n")


if __name__ == "__main__":
    main()