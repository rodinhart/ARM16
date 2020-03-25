const MASK_B__ = 0b0000000000000000
const MASK_IMM = 0b0000010000000000
const MASK_LDR = 0b0000100000000000
const MASK_STR = 0b1000100000000000
const MASK_SWI = 0b0000110000000000
const MASK_ALU = 0b0000110000000001

const MAP_CONDS = {
  nv: 0,
  eq: 1,
  ne: 2,
  cs: 3,
  hs: 3,
  cc: 4,
  lo: 4,
  mi: 5,
  pl: 6,
  vs: 7,
  vc: 8,
  hi: 9,
  ls: 10,
  ge: 11,
  lt: 12,
  gt: 13,
  le: 14,
  al: 15
}

const MAP_DATAOPS = {
  mov: 0,
  and: 1,
  orr: 2,
  eor: 3,
  add: 4,
  adc: 5,
  sub: 6,
  sbc: 7,
  lsl: 8,
  asl: 8,
  lsr: 9,
  asr: 10,
  ror: 11,
  rrx: 12,
  cmp: 13,
  tst: 14
}

const MAP_SWIS = {
  OS_WriteL: 0
}

const lookup = (table, value) => {
  for (const key of Object.keys(table)) {
    if (table[key] === value) return key
  }

  throw new Error(`Failed to lookup ${value}`)
}

const toBits = o => ("000000000000000" + o.toString(2)).substr(-16)
const toChar = o => (o >= 32 && o < 128 ? String.fromCharCode(o) : " ")
const toWord = o => ("000" + o.toString(16)).substr(-4)

const assemble = code => {
  const lines = code
    .split("\n")
    .map(line => line.trim())
    .filter(line => line.length)

  const labels = {}
  let mem = new DataView(new ArrayBuffer(65536))
  let pc
  let pass

  const assembly = [
    // .label
    "^\\.(\\w+)$",
    label => {
      labels[label] = pc
    },

    // DCS "Hello, World"
    '^DCS "([\\w\\s]+)"$',
    s => {
      for (let i = 0; i < s.length; i++) {
        mem.setUint8(pc++, s.charCodeAt(i))
      }
    },

    // DCB 42
    "^DCB ([0-9]+)$",
    b => {
      mem.setUint8(pc++, b)
    },

    // ALIGN
    "^ALIGN$",
    () => {
      if (pc % 2) pc++
    },

    // ADR r1, hello
    "^ADR r([0-7]), (\\w+)$",
    (a, label) => {
      if (pass === 1 && labels[label] === undefined) {
        throw new Error(`No such ADR label ${label}`)
      }
      const x = pass === 0 ? 0 : labels[label] - (pc + 2)
      if (x > 255 || x < -256) {
        throw new Error(`ADR label ${label} out of range`)
      }

      const d = MAP_DATAOPS[x < 0 ? "sub" : "add"]

      mem.setUint16(
        pc,
        MASK_ALU | (MAP_DATAOPS["mov"] << 12) | (a << 7) | (7 << 4)
      )
      pc += 2

      mem.setUint16(pc, MASK_IMM | (d << 12) | (a << 7) | (Math.abs(x) & 0x7f))
      pc += 2
    },

    // DCW 2782
    "^([0-9]+)$",
    w => {
      mem.setUint16(pc, w)
      pc += 2
    },

    // B<c> label
    `^b(${Object.keys(MAP_CONDS).join("|")})? (\\w+)$`,
    (cond, label) => {
      const c = MAP_CONDS[cond || "al"]

      if (pass === 1 && labels[label] === undefined) {
        throw new Error(`No such B label ${label}`)
      }

      const x = pass === 0 ? 0 : labels[label] - (pc + 2)
      if (x > 1022 || x < -1024) {
        throw new Error(`B label ${label} out of range`)
      }

      mem.setUint16(pc, MASK_B__ | (c << 12) | ((x >>> 1) & 0x3ff))
      pc += 2
    },

    // ALU r1, #23
    `^(${Object.keys(MAP_DATAOPS).join("|")}) r([0-7]), #([0-9]+)$`,
    (alu, a, x) => {
      const d = MAP_DATAOPS[alu]
      if (x > 127 || x < 0) {
        throw new Error(`Immediate ${x} out of range`)
      }

      mem.setUint16(pc, MASK_IMM | (d << 12) | (a << 7) | (x & 0x7f))
      pc += 2
    },

    // LDR r1, [r2, #0]
    "^(ldr|str) r([0-7]), \\[r([0-7], #([0-9]+))\\]$",
    (dir, m, a, x) => {
      const msk = dir === "ldr" ? MASK_LDR : MASK_STR
      if (x > 127) {
        throw new Error(`Offset ${x} out of range`)
      }

      mem.setUint16(pc, msk | (m << 12) | (a << 7) | (x & 0x7f))
      pc += 2
    },

    // SWI x
    "^swi (\\w+)$",
    name => {
      const x = MAP_SWIS[name]
      if (x === undefined) {
        throw new Error(`Unknown SWI ${name}`)
      }

      mem.setUint16(pc, MASK_SWI | (x << 1))
      pc += 2
    },

    // ALU r1, r2
    `^(${Object.keys(MAP_DATAOPS).join("|")}) r([0-7]), r([0-7])$`,
    (alu, a, m) => {
      const d = MAP_DATAOPS[alu]
      mem.setUint16(pc, MASK_ALU | (d << 12) | (a << 7) | (m << 4))
      pc += 2
    }
  ]

  for (pass = 0; pass < 2; pass++) {
    pc = 0
    lines.forEach(line => {
      for (let i = 0; i < assembly.length; i += 2) {
        const reg = new RegExp(assembly[i])
        const match = reg.exec(line)
        if (match) {
          assembly[i + 1](...match.slice(1))
          return
        }
      }

      throw new Error(`Unknown assembly ${line}`)
    })
  }

  return { mem, pc }
}

const interp = (word, actions, r) => {
  if ((word & 0b0000110000000000) === MASK_B__) {
    const c = lookup(MAP_CONDS, word >>> 12)
    const x = (word << 22) >> 22

    return actions["b"](r, c, x)
  } else if ((word & 0b0000110000000000) === MASK_IMM) {
    const d = lookup(MAP_DATAOPS, (word >>> 12) & 0xf)
    const a = (word >>> 7) & 7
    const x = word & 0x7f

    return actions["imm"](r, a, d, x)
  } else if ((word & 0b1000110000000000) === MASK_LDR) {
    const m = (word >>> 12) & 7
    const a = (word >>> 7) & 7
    const x = word & 0x7f

    return actions["ldr"](r, a, m, x)
  } else if ((word & 0b1000110000000000) === MASK_STR) {
    const m = (word >>> 12) & 7
    const a = (word >>> 7) & 7
    const x = word & 0x7f

    return actions["str"](r, a, m, x)
  } else if ((word & 0b0000110000000001) === MASK_SWI) {
    const x = lookup(MAP_SWIS, (word >>> 1) & 0x8ff)

    return actions["swi"](r, x)
  } else if ((word & 0b0000110000000001) === MASK_ALU) {
    const d = lookup(MAP_DATAOPS, (word >>> 12) & 0xf)
    const a = (word >>> 7) & 7
    const m = (word >>> 4) & 7

    return actions["alu"](r, a, m, d)
  } else {
    throw new Error(`Unknown instruction ${toBits(word)}`)
  }
}

const disassem = (mem, len) => {
  const actions = pc => ({
    b: (r, c, x) => {
      r.push(`b${c === "al" ? "" : c} 0x${toWord(pc + 2 + (x << 1))}`)

      return r
    },

    imm: (r, a, d, x) => {
      r.push(`${d} r${a}, #${x}`)

      return r
    },

    ldr: (r, a, m, x) => {
      r.push(`ldr r${m}, [r${a}, #${x}]`)

      return r
    },

    str: (r, a, m, x) => {
      r.push(`str r${m}, [r${a}, #${x}]`)

      return r
    },

    swi: (r, x) => {
      r.push(`swi ${x}`)

      return r
    },

    alu: (r, a, m, d) => {
      r.push(`${d} r${a}, r${m}`)

      return r
    }
  })

  const r = []
  for (let pc = 0; pc < len; pc += 2) {
    const word = mem.getUint16(pc)
    try {
      interp(word, actions(pc), r)
    } catch (e) {
      r.push(`DCW ${toWord(word)}`)
    }

    r[r.length - 1] = `${toWord(pc)}  ${toChar(word >>> 8)}${toChar(
      word & 0xff
    )}  ${toWord(word)}  ${r[r.length - 1]}`
  }

  return r
}

const exec_ = {
  mov: (a, m) => m,
  and: (a, m) => a & m,
  orr: (a, m) => a | m,
  eor: (a, m) => a ^ m,
  add: (a, m) => a + m,
  adc: (a, m, C) => a + m + C,
  sub: (a, m) => a - m,
  sbc: (a, m, C) => a - m,
  lsl: (a, m) => a << m,
  lsr: (a, m) => a >>> m,
  asr: (a, m) => (a << 16) >> (16 + m),
  ror: (a, m) => (a >> m) | (a << (16 - m)),
  rrx: (a, m) => a >> m,
  cmp: (a, m) => a - m,
  tst: (a, m) => a & m
}

const exec = (actions => (mem, len) => {
  let r = {
    mem,
    regs: [0, 0, 0, 0, 0, 0, 0, 0],
    flags: {
      C: 0,
      N: 0,
      V: 0,
      Z: 0
    }
  }

  while (r.regs[7] < len) {
    const ir = mem.getUint16(r.regs[7])
    r.regs[7] += 2
    r = interp(ir, actions, r)
  }

  return {
    regs: r.regs,
    flags: r.flags
  }
})({
  b: (r, c, x) => {
    r.regs[7] += x << 1

    return r
  },

  imm: (r, a, d, x) => {
    const t = exec_[d](r.regs[a], x, r.flags.C)
    r.flags.C = t & 0x10000 ? 1 : 0
    r.flags.N = t & 0x8000 ? 1 : 0
    r.flags.V = t & 0x20000 ? 1 : 0
    r.regs[a] = (t << 16) >> 16
    r.flags.Z = r.regs[a] === 0 ? 1 : 0

    return r
  },

  ldr: (r, a, m, x) => {
    const offset = (r.regs[a] + x) & 0xffff
    r.regs[m] = r.mem.getUint16(offset) // bytes!
    r.regs[m] = (r.regs[m] << 16) >> 16

    return r
  },

  str: (r, a, m, x) => {
    const offset = (r.regs[a] + x) & 0xffff
    r.mem.setUint16(offset, r.regs[m]) // bytes!

    return r
  },

  swi: (r, x) => {
    let s = ""
    let i = 0
    while (r.mem.getUint8(r.regs[0] + i) !== 0) {
      s += String.fromCharCode(r.mem.getUint8(r.regs[0] + i))
      i++
    }

    console.log(s)

    return r
  },

  alu: (r, a, m, d) => {
    const t = exec_[d](r.regs[a], r.regs[m], r.flags.C)
    r.flags.C = t & 0x10000 ? 1 : 0
    r.flags.N = t & 0x8000 ? 1 : 0
    r.flags.V = t & 0x20000 ? 1 : 0
    r.regs[a] = (t << 16) >> 16
    r.flags.Z = r.regs[a] === 0 ? 1 : 0

    return r
  }
})

let code = `
  mov r5, #1
  lsl r5, #16

  mov r0, #4

  mov r6, r7
  add r6, #4
  b inc

  mov r6, r7
  add r6, #4
  b inc

  b end

.inc
  add r0, #1
  mov r7, r6
.end
`

const { pc: len, mem } = assemble(code)

console.log("Disassembled")
console.log(disassem(mem, len).join("\n"))
console.log()

console.log("Execute")
console.log(exec(mem, len))
