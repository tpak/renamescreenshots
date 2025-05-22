# filepath: /screenshotrename/screenshotrename/src/streamlit_app.py
import os

import streamlit as st

from rename_screenshots import rename_screenshots


def main():
    st.title("Screenshot Renamer")

    st.write("Select a directory containing screenshot files to rename them.")

    directory = st.text_input(
        "Directory", value=os.path.expanduser("~/Desktop/Screenshots")
    )

    if st.button("Rename Screenshots"):
        if os.path.isdir(directory):
            total_files, renamed_files = rename_screenshots(directory)
            st.success(f"Total files iterated: {total_files}")
            st.success(f"Total files renamed: {renamed_files}")
        else:
            st.error("The specified directory does not exist.")


if __name__ == "__main__":
    main()
n()
