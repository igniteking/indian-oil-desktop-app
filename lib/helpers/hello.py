import sys

def main():
    if len(sys.argv) > 1:
        input_string = sys.argv[1]
        print(f"Received input: {input_string}")
    else:
        print("No input received.")

if __name__ == "__main__":
    main()
