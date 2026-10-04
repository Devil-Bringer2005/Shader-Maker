using UnityEngine;

public class Connector : MonoBehaviour
{
    public Vector2 size = new Vector2(4,4);
    public bool isConnected = false;

    bool isPlaying;

    private void Start()
    {
        isPlaying = true;
    }
    private void OnDrawGizmos()
    {   
        if (!isPlaying) { Gizmos.color = Color.cyan; }
        Gizmos.color = isConnected ? Color.green : Color.red;
        Vector2 halfSize = size * 0.5f;
        Vector3 offset = transform.position + transform.up * halfSize.y;
        Gizmos.DrawLine(offset, offset + transform.forward);

        // Defining Top and Side Vectors
        Vector3 top = transform.up * size.y; // top side
        Vector3 side = transform.right * halfSize.x; // right side

        // Defining Corner Vectors
        Vector3 topRight = transform.position + top + side;
        Vector3 topLeft = transform.position + top - side;
        Vector3 bottomRight = transform.position + side;
        Vector3 bottomLeft = transform.position - side;

        // Draw Corner Lines
        Gizmos.DrawLine(topRight,topLeft);
        Gizmos.DrawLine(topLeft,bottomLeft);
        Gizmos.DrawLine(bottomLeft,bottomRight);
        Gizmos.DrawLine(bottomRight,topRight);

        // Draw Diagonal Lines
        Gizmos.DrawLine(topRight,offset);
        Gizmos.DrawLine(topLeft,offset);
        Gizmos.DrawLine(bottomLeft,offset);
        Gizmos.DrawLine(bottomRight,offset);
    }
}
