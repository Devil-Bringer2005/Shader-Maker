using UnityEngine;

public class ToggleDoor : MonoBehaviour
{   
    private Animator myAnim;
    private bool isInZone;

    // Start is called once before the first execution of Update after the MonoBehaviour is created
    void Start()
    {
          myAnim = GetComponent<Animator>();
    }

    // Update is called once per frame
    void Update()
    {
        if (isInZone && Input.GetKeyDown(KeyCode.E))
        {
            bool isOpen = myAnim.GetBool("isOpen");
            myAnim.SetBool("isOpen", !isOpen);
        }
    }

    private void OnTriggerEnter(Collider other)
    {   
        if(other.gameObject.tag == "Player")
        {
            isInZone = true;
        }
            
    }
    private void OnTriggerExit(Collider other)
    {
        if (other.gameObject.tag == "Player")
        {
            isInZone = false;
        }
    }
}
