using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class PieceGenerator : MonoBehaviour
{
    [SerializeField] private GameObject piecePrefab;

    private int colCount = 10;
    private int rowCount = 10;

    private Mesh[,] pieceMeshArray;

    private bool[,] topConnector;
    private bool[,] rightConnector;

    private void Start()
    {
        float uvWidth = 1.0f / colCount;
        float uvHeight = 1.0f / rowCount;

        Vector3 offset = Vector3.zero;
        offset.x = -(float) colCount / 2.0f + .475f;
        offset.y = -(float) rowCount / 2.0f + .475f;
        float startX = offset.x;

        pieceMeshArray = new Mesh[colCount, rowCount];
        topConnector = new bool[colCount, rowCount];
        rightConnector = new bool[colCount, rowCount];

        for (int j = 0; j < rowCount; j++)
        {
            for (int i = 0; i < colCount; i++)
            {
                GameObject pieceGameObject = ((GameObject) Instantiate(piecePrefab));
                pieceGameObject.transform.SetParent(this.gameObject.transform);
                pieceGameObject.transform.position = offset;
                Mesh mesh = pieceGameObject.GetComponent<MeshFilter>().mesh;
                pieceGameObject.transform.localScale = new Vector3(1, 1, 1);
                pieceMeshArray[i, j] = mesh;
                Vector2[] uvs = mesh.uv;

                //Store the original UVs to be used by the masks.
                Vector2[] uv2s = mesh.uv;

                //Set the UVs to be encompass neighboring pieces which will be masked out in the shader.
                uvs[0] = new Vector2((i - 1) * uvWidth, (j - 1) * uvHeight);
                uvs[3] = new Vector2((i - 1) * uvWidth, (j + 2) * uvHeight);
                uvs[1] = new Vector2((i + 2) * uvWidth, (j + 2) * uvHeight);
                uvs[2] = new Vector2((i + 2) * uvWidth, (j - 1) * uvHeight);

                mesh.uv = uvs;
                mesh.uv2 = uv2s;

                offset.x += 0.3345f;
            }

            offset.y += 0.3345f;
            offset.x = startX;
        }

        this.transform.localScale = new Vector3(1.5f, 1, 1);

        //The logic below is used to pass data through a mesh's vertex color array to use later in the shader.
        //At the moment it randomly generates a valid jigsaw pattern.
        for (int j = 0; j < rowCount; j++)
        {
            for (int i = 0; i < colCount; i++)
            {
                Mesh mesh = pieceMeshArray[i, j];

                int leftMask = 2;
                if (i > 0)
                {
                    leftMask = rightConnector[i - 1, j] ? 1 : 0;
                }

                int rightMask = 2;
                if (i < colCount - 1)
                {
                    rightMask = Random.Range(0, 2) == 0 ? 0 : 1;
                    if (rightMask == 0)
                    {
                        rightConnector[i, j] = true;
                    }
                }

                int topMask = 2;
                if (j < rowCount - 1)
                {
                    topMask = Random.Range(0, 2) == 0 ? 0 : 1;
                    if (topMask == 0)
                    {
                        topConnector[i, j] = true;
                    }
                }

                int botMask = 2;
                if (j > 0)
                {
                    botMask = topConnector[i, j - 1] ? 1 : 0;
                }

                Color combinationMask = new Color(leftMask, rightMask, topMask, botMask);
                mesh.SetColors(new List<Color>() {combinationMask, combinationMask, combinationMask, combinationMask});
            }
        }
    }
}