# alpsanger

**Sanger sequencing nanobody annotation pipeline**

Processes Sanger sequencing data (`.ab1` or `.fasta`) through basecalling, quality control, IgBLAST annotation against alpaca germline references, and R-based post-processing into a formatted Excel sheet.

---

## Strict syntax note

This pipeline requires Nextflow ≥ 24.04.0 and is written for the strict syntax parser. Enable it explicitly if needed:

```bash
export NXF_SYNTAX_PARSER=v2
nextflow run main.nf ...
```

From Nextflow 26.04.0+, strict syntax is the default.
