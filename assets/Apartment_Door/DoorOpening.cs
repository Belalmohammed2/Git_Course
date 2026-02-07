using Unity.VisualScripting;
using UnityEngine;

public class DoorOpening : MonoBehaviour
{
    private bool isPlayerNearBy;
    private bool isOpen;
    [SerializeField] private Transform meshTrasnform;

    void Update()
    {
        if (isPlayerNearBy && Input.GetKeyDown(KeyCode.E))
        {
            isOpen = !isOpen;
        }
        float targetAngle = isOpen ? 90f : 0f;
        Quaternion targetRotation = Quaternion.Euler(0, targetAngle, 0);
        meshTrasnform.localRotation = Quaternion.Slerp(meshTrasnform.localRotation, targetRotation, 5 * Time.deltaTime);

    }

    void OnTriggerEnter()
    {
        isPlayerNearBy = true;
    }
    void OnTriggerExit()
    {
        isPlayerNearBy = false;
    }
}


