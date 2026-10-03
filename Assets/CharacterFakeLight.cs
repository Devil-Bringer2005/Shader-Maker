using UnityEngine;

public class CharacterFakeLight : MonoBehaviour
{
    public Renderer characterRenderer;
    public Vector3 localLightDir = new Vector3(0.3f, 0.7f, 0.6f);

    MaterialPropertyBlock mpb;

    void Awake()
    {
        mpb = new MaterialPropertyBlock();
    }

    void LateUpdate()
    {
        Vector3 worldDir = transform.TransformDirection(localLightDir).normalized;

        characterRenderer.GetPropertyBlock(mpb);
        mpb.SetVector("_LightDir", worldDir);
        characterRenderer.SetPropertyBlock(mpb);
    }
}
