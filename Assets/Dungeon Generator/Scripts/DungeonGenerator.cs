using System.Collections;
using System.Collections.Generic;
using System.Linq;
using Unity.VisualScripting;
using UnityEngine;
using UnityEngine.SceneManagement;
using static UnityEngine.InputManagerEntry;


[System.Serializable]
public class SpawnableBlocks
{
    public GameObject prefab;
    [Range(0,100)] public int spawnRate = 100;
    public int maxSpawnCount = -1;

    [HideInInspector]
    public int currentSpawnCount = 0;
}
public enum DungeonState { inactive, generatingMain, generatingBranch, cleanUp, completed }
public class DungeonGenerator : MonoBehaviour
{   
    [SerializeField] private SpawnableBlocks[] startPrefabs;
    [SerializeField] private SpawnableBlocks[] exitPrefabs;
    [SerializeField] private SpawnableBlocks[] tilePrefabs;
    [SerializeField] private SpawnableBlocks[] blockedPrefabs;
    [SerializeField] private SpawnableBlocks[] doorPrefabs;

    [Header("Debugging Options")]
    [Space]
    [SerializeField] private bool useBoxColliders;
    [SerializeField] private bool useLightsForDebugging;
    [SerializeField] private bool restoreLightsForDebugging;

    [Header("KeyBindings")]
    [Space]
    [SerializeField] private KeyCode reloadMap = KeyCode.R;
    [SerializeField] private KeyCode toggleMap = KeyCode.T;

    [Header("Generation Limits")]
    [Space]
    [SerializeField] private int mainLength = 10;
    [SerializeField] private int branchingLength = 5;
    [SerializeField] private int numBranches = 10;
    [Range(0, 100)] [SerializeField] private int doorPercent = 25;
    [SerializeField] private float constructionDelay = 1f;

    [Header("Available at Runtime")]
    [Space]
    public DungeonState dungeonState = DungeonState.inactive;
    public List<Tile> generatedTiles = new List<Tile>();

    GameObject goCamera, goPlayer;
    List<Connector> availableConnectors = new List<Connector>();

    private Color startLightColor = Color.white;

    private Transform tileFrom, tileTo,tileRoot;
    private Transform container;

    private int attempts;
    private int maxAttempts = 500;


    // Start is called once before the first execution of Update after the MonoBehaviour is created
    void Start()
    {
        goCamera = GameObject.Find("Overhead Camera");
        goPlayer = GameObject.FindWithTag("Player");
        StartCoroutine(DungeonBuild());
    }

    private void Update()
    {
        //if (Input.GetKeyDown(reloadMap))
        //{
        //    SceneManager.LoadScene("Dungeon Generator");
        //}
        //if (Input.GetKeyDown(toggleMap))
        //{
        //    goCamera.SetActive(!goCamera.activeInHierarchy);
        //    goPlayer.SetActive(!goPlayer.activeInHierarchy);
        //}
    }

    IEnumerator DungeonBuild()
    {   
        goCamera.SetActive(true);
        goPlayer.SetActive(false);
        GameObject goContainer = new GameObject("Main");
        container = goContainer.transform;
        container.SetParent(transform);
        tileRoot = CreateStartTile();
        DebugRoomLighting(tileRoot, Color.cyan);
        tileTo = tileRoot;
        dungeonState = DungeonState.generatingMain;
        while(generatedTiles.Count < mainLength)
        {
            yield return new WaitForSeconds(constructionDelay);
            tileFrom = tileTo;
            if(generatedTiles.Count == mainLength - 1)
            {
                // Exit room 
                tileTo = CreateExitTile();
                DebugRoomLighting(tileTo, Color.red);
            }
            else
            {
                tileTo = CreateTile();
                DebugRoomLighting(tileTo, Color.yellow);
            }
           
            ConnectTiles();
            CollisionCheck();
        }

        // get all connectors within container that are not connected
        foreach(Connector connector in container.GetComponentsInChildren<Connector>())
        {
            if (!connector.isConnected)
            {
                if (!availableConnectors.Contains(connector))
                {
                    availableConnectors.Add(connector);
                }
            }
        }

        // Branching
        dungeonState = DungeonState.generatingBranch;
        for (int b = 0; b < numBranches; b++)
        {
            if (availableConnectors.Count > 0)
            {
                goContainer = new GameObject("Branch" + (b + 1));
                container = goContainer.transform;
                container.SetParent(transform);
                int availableIndex = Random.Range(0, availableConnectors.Count);
                tileRoot = availableConnectors[availableIndex].transform.parent.parent;
                availableConnectors.RemoveAt(availableIndex);
                tileTo = tileRoot;
                for (int i = 0; i < branchingLength - 1; i++)
                {
                    yield return new WaitForSeconds(constructionDelay);
                    tileFrom = tileTo;
                    tileTo = CreateTile();
                    DebugRoomLighting(tileTo, Color.green);
                    ConnectTiles();
                    CollisionCheck();
                    if (attempts >= maxAttempts) { break; }
                }
            }
            else { break; }
        }
        dungeonState = DungeonState.cleanUp;
        LightRestoration();
        CleanUpBoxColliders();
        BlockedPassages();
        SpawnDoors();
        dungeonState = DungeonState.completed;
        yield return null;
        goCamera.SetActive(false);
        goPlayer.SetActive(true);
    }

    void ConnectTiles()
    {
        Transform connectFrom = GetRandomConnector(tileFrom);
        if(connectFrom == null) { return; }
        Transform connectTo = GetRandomConnector(tileTo);
        if(connectTo == null) { return; };

        connectTo.SetParent(connectFrom);
        tileTo.SetParent(connectTo);
        connectTo.localPosition = Vector3.zero;
        connectTo.localRotation = Quaternion.identity;
        connectTo.Rotate(0,180f,0);
        tileTo.SetParent(container);
        connectTo.SetParent(tileTo.Find("Connectors"));
        generatedTiles.Last().connector = connectFrom.GetComponent<Connector>();
    }
    private Transform GetRoomTransform(Transform tile)
    {
        foreach (Transform child in tile.GetComponentsInChildren<Transform>(true))
        {
            if (child.CompareTag("Room"))
                return child;
        }
        return null;
    }
    private Transform GetRandomConnector(Transform tile)
    {   
        if (tile == null) { return null; }

        List<Connector> connectorList = tile.GetComponentsInChildren<Connector>().ToList().FindAll(x => x.isConnected == false);
        if(connectorList.Count > 0)
        {
            int connectorIndex = Random.Range(0,connectorList.Count);
            connectorList[connectorIndex].isConnected = true;
            if (tile == tileFrom)
            {
                Transform room = GetRoomTransform(tile);

                if (room != null)
                {
                    if (!room.TryGetComponent(out BoxCollider box))
                    {
                        box = room.gameObject.AddComponent<BoxCollider>();
                        box.isTrigger = true;
                    }
                }
                else
                {
                    Debug.LogError("Room tag not found in " + tile.name);
                }
            }
            return connectorList[connectorIndex].transform;
        }
        return null;
    }

    Transform CreateTile()
    {
        //int index = Random.Range(0, tilePrefabs.Length);
        GameObject goTile = Instantiate(GetRandomBlock(tilePrefabs), Vector3.zero, Quaternion.identity, container);
        //goTile.name = GetRandomBlock(tilePrefabs).name;
        Transform origin = generatedTiles[generatedTiles.FindIndex(x => x.tile == tileFrom)].tile;
        generatedTiles.Add(new Tile(goTile.transform, origin));
        return goTile.transform;
    }
    Transform CreateExitTile()
    {
        //int index = Random.Range(0, exitPrefabs.Length);
        GameObject goTile = Instantiate(GetRandomBlock(exitPrefabs), Vector3.zero,Quaternion.identity,container);
        goTile.name = "Exit Room";
        Transform origin = generatedTiles[generatedTiles.FindIndex(x => x.tile == tileFrom)].tile;
        generatedTiles.Add(new Tile(goTile.transform, origin));
        return goTile.transform;
    }

    Transform CreateStartTile()
    {
        //int index = Random.Range(0, startPrefabs.Length);
        GameObject goTile = Instantiate(GetRandomBlock(startPrefabs), Vector3.zero, Quaternion.identity,container);
        goTile.name = "Start Room";
        float yRotation = Random.Range(0, 4) * 90f;
        goTile.transform.Rotate(0f, yRotation, 0f);
        generatedTiles.Add(new Tile(goTile.transform, null));
        return goTile.transform;
    }

    private GameObject GetRandomBlock(SpawnableBlocks[] prefabList)
    {
        SpawnableBlocks[] validPrefabs = prefabList.Where (x => x.maxSpawnCount < 0 || x.currentSpawnCount < x.maxSpawnCount).ToArray();

        if(validPrefabs.Length == 0)
        {
            return null;
        }

        // Calculate total weight
        int totalWeight = validPrefabs.Sum(x => x.spawnRate);
        int randomPoint = Random.Range(0, totalWeight);

        foreach (var prefab in validPrefabs)
        {
            if (randomPoint < prefab.spawnRate)
            {
                prefab.currentSpawnCount++;
                return prefab.prefab;
            }
            randomPoint -= prefab.spawnRate;
        }

        return null;
    }
    Transform GetTileRoot(Transform t)
    {
        while (t.parent != null && !generatedTiles.Exists(x => x.tile == t))
        {
            t = t.parent;
        }
        return t;
    }

    void CollisionCheck()
    {
     
        Transform room = tileTo.GetComponentsInChildren<Transform>()
                           .FirstOrDefault(t => t.CompareTag("Room"));

        if (room == null)
        {
            Debug.LogError($"Tile {tileTo.name} has NO child tagged 'Room'");
            return;
        }

        // Ensure BoxCollider on Room
        BoxCollider box = room.GetComponent<BoxCollider>();
        if (box == null)
        {
            box = room.gameObject.AddComponent<BoxCollider>();
            box.isTrigger = true;
        }
        Vector3 worldCenter = room.TransformPoint(box.center); // world-space center
        Vector3 halfExtents2 = Vector3.Scale(box.size * 0.5f, room.lossyScale);
        Quaternion rotation = room.rotation;

        Vector3 offset = (tileTo.right * box.center.x) + (tileTo.up * box.center.y) + (tileTo.forward * box.center.z);
        Vector3 halfExtents = box.bounds.extents;
        List<Collider> hits = Physics.OverlapBox(worldCenter, halfExtents2, room.rotation, LayerMask.GetMask("Room")).ToList();
        if (hits.Count > 0)
        {
            if (hits.Exists(x =>
            {
                Transform hitTile = GetTileRoot(x.transform);
                return hitTile != tileFrom && hitTile != tileTo;
            }))

            {
                // hit something (other than tileFrom or tileTo)
                attempts++;
                int toIndex = generatedTiles.FindIndex(x => x.tile == tileTo);
                if (generatedTiles[toIndex].connector != null)
                {
                    generatedTiles[toIndex].connector.isConnected = false;
                }
                generatedTiles.RemoveAt(toIndex);
                DestroyImmediate(tileTo.gameObject);
                // backtracking
                if (attempts >= maxAttempts)
                {
                    int fromIndex = generatedTiles.FindIndex(x => x.tile == tileFrom);
                    Tile myTileFrom = generatedTiles[fromIndex];
                    if (tileFrom != tileRoot)
                    {
                        if (myTileFrom.connector != null)
                        {
                            myTileFrom.connector.isConnected = false;
                        }
                        availableConnectors.RemoveAll(x => x.transform.parent.parent == tileFrom);
                        generatedTiles.RemoveAt(fromIndex);
                        DestroyImmediate(tileFrom.gameObject);
                        if (myTileFrom.origin != tileRoot)
                        {
                            tileFrom = myTileFrom.origin;
                        }
                        else if (container.name.Contains("Main"))
                        {
                            if (myTileFrom.origin != null)
                            {
                                tileRoot = myTileFrom.origin;
                                tileFrom = tileRoot;
                            }
                        }
                        else if (availableConnectors.Count > 0)
                        {
                            int availIndex = Random.Range(0, availableConnectors.Count);
                            tileRoot = availableConnectors[availIndex].transform.parent.parent;
                            availableConnectors.RemoveAt(availIndex);
                            tileFrom = tileRoot;
                        }
                        else { return; }

                    }
                    else if (container.name.Contains("Main"))
                    {
                        if (myTileFrom.origin != null)
                        {
                            tileRoot = myTileFrom.origin;
                            tileFrom = tileRoot;
                        }
                    }
                    else if (availableConnectors.Count > 0)
                    {
                        int availIndex = Random.Range(0, availableConnectors.Count);
                        tileRoot = availableConnectors[availIndex].transform.parent.parent;
                        availableConnectors.RemoveAt(availIndex);
                        tileFrom = tileRoot;
                    }
                    else { return; }
                }
                // retry
                if (tileFrom != null)
                {
                    if (generatedTiles.Count == mainLength - 1)
                    {
                        // Exit room 
                        tileTo = CreateExitTile();
                        DebugRoomLighting(tileTo, Color.red);
                    }
                    else
                    {
                        tileTo = CreateTile();
                        Color retryColor = container.name.Contains("Branch") ? Color.purple : Color.yellow;
                        DebugRoomLighting(tileTo, retryColor * 2f);
                    }   
                    ConnectTiles();
                    CollisionCheck();
                }
            }
            
            else
            {
                attempts = 0;
            }
        }
       
       
    }

    // Light Color debugger
    void DebugRoomLighting(Transform tile , Color lightColor)
    {
        if (useLightsForDebugging && Application.isEditor)
        {
            Light[] lights = tile.GetComponentsInChildren<Light>();
            if(lights.Length > 0)
            {
                if (startLightColor == Color.white)
                {
                    startLightColor = lights[0].color;
                }
                foreach(Light light in lights)
                {
                    light.color = lightColor;
                }
            }
        }
    }

    void LightRestoration()
    {
        if (useLightsForDebugging && restoreLightsForDebugging && Application.isEditor)
        {
            Light[] lights = transform.GetComponentsInChildren<Light>();
            foreach (Light light in lights)
            {
                light.color = startLightColor;
            }
        }
    }

    void CleanUpBoxColliders()
    {
        if (!useBoxColliders)
        {
            foreach(Tile myTile in generatedTiles)
            {
                BoxCollider box = myTile.tile.GetComponentInChildren<BoxCollider>();
                if(box != null)
                {
                    Destroy(box);
                }
            }
        }
    }
    
    void SpawnDoors()
    {
        if(doorPercent > 0)
        {
            Connector[] allConnectors = transform.GetComponentsInChildren<Connector>();
            for(int i = 0; i < allConnectors.Length; i++)
            {
                Connector myConnector = allConnectors[i];
                if (myConnector.isConnected)
                {   
                    // Random chance for spawning door
                    int roll = Random.Range(1, 101);
                    if(roll <= doorPercent)
                    {
                        Vector3 halfExtents = new Vector3(myConnector.size.x, 1f, myConnector.size.x);
                        Vector3 pos = myConnector.transform.position;
                        Vector3 offset = Vector3.up * 0.5f;
                        Collider[] hits = Physics.OverlapBox(pos + offset, halfExtents, Quaternion.identity, LayerMask.GetMask("Door"));
                        if (hits.Length == 0)
                        {   

                            int doorIndex = Random.Range(0, doorPrefabs.Length);
                            GameObject goDoor = Instantiate(GetRandomBlock(doorPrefabs),pos,myConnector.transform.rotation,myConnector.transform) as GameObject;
                            //goDoor.name = GetRandomBlock(doorPrefabs).name;
                        }
                    }
                }
            }
        }
    }

    // need to add collision check for blocked paths
    void BlockedPassages()
    {   
        foreach(Connector connector in transform.GetComponentsInChildren<Connector>())
        {   
            if (!connector.isConnected)
            {
                Vector3 pos = connector.transform.position;
                //int wallIndex = Random.Range(0, blockedPrefabs.Length);
                GameObject goWall = Instantiate(GetRandomBlock(blockedPrefabs), pos, connector.transform.rotation, connector.transform);
                goWall.name = GetRandomBlock(blockedPrefabs).name;
            }
        }
        
    }


}
