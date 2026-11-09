"""SB-M43-172: build scrubbots_notify.aar with javac only (no Gradle, no downloads).

The Godot classes come from the export templates' android_source.zip (godot-lib aar), the
Android API from the SDK's android.jar. Output: the AAR the addons/scrubbots_notify export
plugin hands to Godot's Gradle build.

  python build_aar.py --android-jar <sdk>/platforms/android-N/android.jar \
      --android-source <templates>/android_source.zip --out <path>/scrubbots_notify.aar [--javac javac]
"""
import argparse
import pathlib
import subprocess
import tempfile
import zipfile

HERE = pathlib.Path(__file__).resolve().parent
GODOT_AAR = "libs/release/godot-lib.template_release.aar"


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--android-jar", required=True)
    ap.add_argument("--android-source", required=True)
    ap.add_argument("--out", required=True)
    ap.add_argument("--javac", default="javac")
    a = ap.parse_args()
    with tempfile.TemporaryDirectory() as t:
        tmp = pathlib.Path(t)
        with zipfile.ZipFile(a.android_source) as src, zipfile.ZipFile(src.open(GODOT_AAR)) as aar:
            (tmp / "godot.jar").write_bytes(aar.read("classes.jar"))
        sources = sorted(str(p) for p in (HERE / "src").rglob("*.java"))
        subprocess.run([a.javac, "-source", "8", "-target", "8", "-Xlint:-options", "-Werror",
                        "-bootclasspath", a.android_jar, "-classpath", str(tmp / "godot.jar"),
                        "-d", str(tmp / "classes"), *sources], check=True)
        classes = tmp / "classes.jar"
        with zipfile.ZipFile(classes, "w", zipfile.ZIP_DEFLATED) as z:
            for f in sorted((tmp / "classes").rglob("*.class")):
                z.write(f, f.relative_to(tmp / "classes").as_posix())
        out = pathlib.Path(a.out)
        out.parent.mkdir(parents=True, exist_ok=True)
        with zipfile.ZipFile(out, "w", zipfile.ZIP_DEFLATED) as z:
            z.write(HERE / "AndroidManifest.xml", "AndroidManifest.xml")
            z.write(classes, "classes.jar")
            z.writestr("R.txt", "")
    print("built", out)


if __name__ == "__main__":
    main()
